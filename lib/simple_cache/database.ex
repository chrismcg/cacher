use Amnesia

defdatabase SimpleCache.Database do
  deftable Project, [:title, :description] do
    def insert(title, description) do
      %Project{title: title, description: description} |> Project.write!
    end
  end

  deftable Contributor, [:user_id, :project_title], type: :bag

  deftable User, [:id, :name] do
    def insert(id, name, project_titles) when project_titles != [] do
      Amnesia.transaction do
        %User{id: id, name: name} |> User.write
        Enum.each project_titles, fn title ->
          %Project{title: title} = Project.read(title)
          %Contributor{user_id: id, project_title: title} |> Contributor.write
        end
      end
    end
  end
end
