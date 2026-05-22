use("sample_airbnb");

db.listingsAndReviews.aggregate([
  {
    $group: {
      _id: "$property_type",
      total_listings: { $sum: 1 }
    }
  },
  {
    $sort: { total_listings: -1 }
  }
]);