use("sample_airbnb");

db.listingsAndReviews.updateOne(
  { name: "Mansión de Prueba" },
  {
    $set: {
      price: NumberDecimal("1500.00"),
      "address.country": "United States"
    }
  },
  { upsert: true }
);