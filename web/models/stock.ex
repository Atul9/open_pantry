defmodule OpenPantry.Stock do
  use OpenPantry.Web, :model
  alias OpenPantry.Repo
  schema "stocks" do
    field :quantity, :integer
    field :arrival, Ecto.DateTime
    field :expiration, Ecto.DateTime
    field :reorder_quantity, :integer
    field :aisle, :string
    field :row, :string
    field :shelf, :string
    field :packaging, :string
    field :credits_per_package, :integer
    belongs_to :food, OpenPantry.Food, references: :ndb_no, type: :string
    belongs_to :meal, OpenPantry.Meal
    belongs_to :offer, OpenPantry.Offer
    belongs_to :facility, OpenPantry.Facility
    has_many :stock_distributions, OpenPantry.StockDistribution
    has_many :user_food_packages, through: [:stock_distributions, :user_food_package]

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:quantity, :arrival, :expiration, :reorder_quantity, :aisle, :row, :shelf, :packaging, :credits_per_package, :food_id, :meal_id, :offer_id, :facility_id])
    |> validate_required([:quantity, :facility_id, :packaging])
    |> validate_stockable
  end

  def stockable!(stock) do
    stock.food || stock.meal || stock.offer
  end

  def stockable(stock) do
    stock
    |> stockable_load
    |> stockable!
  end

  def stockable_name(stock) do
    item = stockable(stock)
    case item.__struct__ do
      OpenPantry.Food -> item.longdesc
      _ -> item.name
    end
  end

  def stockable_load(stock) do
    stock
    |> Repo.preload(:food)
    |> Repo.preload(:meal)
    |> Repo.preload(:offer)
  end

  def validate_stockable(changeset) do
    [get_field(changeset, :food_id), get_field(changeset, :meal_id), get_field(changeset, :offer_id)]
    |> Enum.reject(&is_nil/1)
    |> length
    |> handle_stockable_error(changeset)
  end

  def handle_stockable_error(1, changeset), do: changeset
  def handle_stockable_error(0, changeset), do: add_error(changeset, :food_id, "A stock item must stock a food, meal or offer")
  def handle_stockable_error(_, changeset), do: add_error(changeset, :meal_id, "A stock item must stock only one food, meal or offer")



end