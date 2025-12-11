locals {
  # Read the contents of the users.csv file
  users_csv_content = file("users.csv")

  # Decode the CSV content into a list of objects (dictionaries)
  # The 'users' local variable will be a list of user objects.
  users_data = csvdecode(local.users_csv_content)

  users_map = {
    for user in local.users_data :
    "${lower(user.first_name)}.${lower(user.last_name)}" => user
  }

  education_policies = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
  ]

  managers_policies = [
    "arn:aws:iam::aws:policy/IAMReadOnlyAccess",
    "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
  ]

  engineers_policies = [
    "arn:aws:iam::aws:policy/PowerUserAccess",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]
}
