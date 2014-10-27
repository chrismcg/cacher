use Amnesia

defdatabase SimpleCache.Database do
  deftable KeyToPid, [:key, :pid], index: [:pid]
end
