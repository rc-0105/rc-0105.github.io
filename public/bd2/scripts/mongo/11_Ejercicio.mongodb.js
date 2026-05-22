use("sample_airbnb");

db.listingsAndReviews.find(
  { name: { $regex: "Luxury", $options: "i" } },
  { _id: 0, name: 1, price: 1, property_type: 1 }
);