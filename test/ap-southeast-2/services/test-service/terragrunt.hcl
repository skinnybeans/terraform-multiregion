include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "region" {
  path = find_in_parent_folders("region.hcl")
}

include "environment" {
  path = find_in_parent_folders("environment.hcl")
}

dependencies {
  paths = ["../../vpc"]
}



// This works to read in from the VPC module
// but not sure this is better than writing out parameters into parameter store
// dependency "vpc" {
//   config_path = "../../vpc"
// }

// inputs = {
//   vpc_id = dependency.vpc.outputs.vpc_id
// }