use("sample_airbnb");

db.listingsAndReviews.aggregate([
  {
    $match: {
      number_of_reviews: { $gte: 10 }
    }
  },
  {
    $group: {
      _id: null,
      average_review_score: { $avg: "$review_scores.review_scores_rating" }
    }
  }
]);