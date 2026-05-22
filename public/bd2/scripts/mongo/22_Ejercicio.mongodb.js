use("sample_airbnb");

db.listingsAndReviews.aggregate([
  {
    $group: {
      _id: "$address.country",
      average_price: { $avg: "$price" }
    }
  },
  {
    $sort: { average_price: -1 }
  }
]);