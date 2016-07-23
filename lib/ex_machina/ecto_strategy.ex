defmodule ExMachina.EctoStrategy do
  @moduledoc false

  use ExMachina.Strategy, function_name: :insert

  def handle_insert(%{__meta__: %{state: :loaded}} = record, _) do
    raise "You called `insert` on a record that has already been inserted.
     Make sure that you have not accidentally called insert twice.

     The record you attempted to insert:

     #{inspect record, limit: :infinity}"
  end

  def handle_insert(%{__meta__: %{__struct__: Ecto.Schema.Metadata}} = record, %{repo: repo}) do
    record
    |> cast
    |> repo.insert!
  end

  def handle_insert(record, %{repo: _repo}) do
    raise ArgumentError, "#{inspect record} is not an Ecto model. Use `build` instead"
  end

  def handle_insert(_record, _opts) do
    raise "expected :repo to be given to ExMachina.EctoStrategy"
  end

  defp cast(record) do
    record
    |> cast_fields
    |> cast_assocs
  end

  defp cast_fields(struct) do
    struct
    |> ExMachina.Ecto.drop_ecto_fields
    |> Map.keys
    |> cast_fields(struct)
  end

  defp cast_fields(fields, struct) do
    Enum.reduce(fields, struct, fn(field, struct) ->
      casted_value = cast_field(field, struct)
      Map.put(struct, field, casted_value)
    end)
  end

  defp cast_field(field, %{__struct__: schema} = struct) do
    field_type = schema.__schema__(:type, field)
    value = Map.get(struct, field)

    if field_type do
      cast_value(field_type, value, struct)
    else
      value
    end
  end

  defp cast_value(field_type, value, struct) do
    case Ecto.Type.cast(field_type, value) do
      {:ok, value} ->
        value
      _ ->
        raise "Failed to cast `#{value}` of type #{field_type} in #{inspect struct}."
    end
  end

  defp cast_assocs(%{__struct__: schema} = struct) do
    assocs = schema.__schema__(:associations)

    Enum.reduce(assocs, struct, fn(assoc, struct) ->
      original_value = Map.get(struct, assoc)
      casted_value = cast_assoc(original_value)
      Map.put(struct, assoc, casted_value)
    end)
  end

  defp cast_assoc(record) do
    case record do
      %{__meta__: %{__struct__: Ecto.Schema.Metadata, state: :built}} ->
        cast(record)
      records = [_ | _] ->
        Enum.map(records, &(cast(&1)))
      _ ->
        record
    end
  end
end
