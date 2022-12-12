include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "region" {
  path = find_in_parent_folders("region.hcl")
}

include "environment" {
  path = find_in_parent_folders("environment.hcl")
}
