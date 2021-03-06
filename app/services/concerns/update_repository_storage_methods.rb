# frozen_string_literal: true

module UpdateRepositoryStorageMethods
  Error = Class.new(StandardError)
  SameFilesystemError = Class.new(Error)

  attr_reader :repository_storage_move
  delegate :container, :source_storage_name, :destination_storage_name, to: :repository_storage_move

  def initialize(repository_storage_move)
    @repository_storage_move = repository_storage_move
  end

  def execute
    repository_storage_move.with_lock do
      return ServiceResponse.success unless repository_storage_move.scheduled? # rubocop:disable Cop/AvoidReturnFromBlocks

      repository_storage_move.start!
    end

    raise SameFilesystemError if same_filesystem?(source_storage_name, destination_storage_name)

    mirror_repositories

    repository_storage_move.transaction do
      repository_storage_move.finish_replication!

      track_repository(destination_storage_name)
    end

    remove_old_paths
    enqueue_housekeeping

    repository_storage_move.finish_cleanup!

    ServiceResponse.success
  rescue StandardError => e
    repository_storage_move.do_fail!

    Gitlab::ErrorTracking.track_exception(e, container_klass: container.class.to_s, container_path: container.full_path)

    ServiceResponse.error(
      message: s_("UpdateRepositoryStorage|Error moving repository storage for %{container_full_path} - %{message}") % { container_full_path: container.full_path, message: e.message }
    )
  end

  private

  def track_repository(destination_shard)
    raise NotImplementedError
  end

  def mirror_repositories
    raise NotImplementedError
  end

  def mirror_repository(type:)
    unless wait_for_pushes(type)
      raise Error, s_('UpdateRepositoryStorage|Timeout waiting for %{type} repository pushes') % { type: type.name }
    end

    repository = type.repository_for(container)
    full_path = repository.full_path
    raw_repository = repository.raw
    checksum = repository.checksum

    # Initialize a git repository on the target path
    new_repository = Gitlab::Git::Repository.new(
      destination_storage_name,
      raw_repository.relative_path,
      raw_repository.gl_repository,
      full_path
    )

    new_repository.replicate(raw_repository)
    new_checksum = new_repository.checksum

    if checksum != new_checksum
      raise Error, s_('UpdateRepositoryStorage|Failed to verify %{type} repository checksum from %{old} to %{new}') % { type: type.name, old: checksum, new: new_checksum }
    end
  end

  def same_filesystem?(old_storage, new_storage)
    Gitlab::GitalyClient.filesystem_id(old_storage) == Gitlab::GitalyClient.filesystem_id(new_storage)
  end

  def remove_old_paths
    if container.repository_exists?
      Gitlab::Git::Repository.new(
        source_storage_name,
        "#{container.disk_path}.git",
        nil,
        nil
      ).remove
    end
  end

  def enqueue_housekeeping
    # no-op
  end

  def wait_for_pushes(type)
    reference_counter = container.reference_counter(type: type)

    # Try for 30 seconds, polling every 10
    3.times do
      return true if reference_counter.value == 0

      sleep 10
    end

    false
  end
end
