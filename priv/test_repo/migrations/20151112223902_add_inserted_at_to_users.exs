defmodule ExMachina.TestRepo.Migrations.AddInsertedAtToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :inserted_at, :datetime
    end
  end
end
