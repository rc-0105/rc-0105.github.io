use("sample_airbnb");

db.listingsAndReviews.find(
  { price: { $ne: null } },
  { _id: 0, name: 1, price: 1, "address.country": 1 }
)
.sort({ price: -1 })
.limit(10);