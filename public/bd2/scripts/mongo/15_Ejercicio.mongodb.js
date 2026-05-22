use("sample_airbnb");

db.listingsAndReviews.find(
  { last_review: null },
  { _id: 0, name: 1, summary: 1, description: 1 }
).sort({ number_of_reviews: -1 });