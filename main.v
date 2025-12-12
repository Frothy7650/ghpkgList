import json
import os

struct Project {
  name    string
  mut: version string
  url     string
}

struct Pkglist {
  projects []Project
}

struct Root_project {
  name    string
  mut: version string
  url     string
}

struct Root_pkglist {
  projects []Root_project
}

fn main() {
  println("Checking for updates...")

  // Load local pkglist
  mut pkglist_raw := os.read_file("pkglist.json") or { eprintln("Failed to read pkglist.json: $err"); return }
  mut pkglist_json := json.decode(Pkglist, pkglist_raw) or { eprintln("Failed to decode pkglist.json: $err"); return }

  // Load root pkglist
  pkglist_root_raw := os.read_file("pkglist_root.json") or { eprintln("Failed to read pkglist_root.json: $err"); return }
  pkglist_root_json := json.decode(Root_pkglist, pkglist_root_raw) or { eprintln("Failed to decode pkglist_root.json: $err"); return }

  // Map root URLs by project name
  mut root_url_map := map[string]string{}
  for project in pkglist_root_json.projects {
    root_url_map[project.name] = project.url
  }

  // Update only the version in local pkglist
  for mut project in pkglist_json.projects {
    if root_url := root_url_map[project.name] {
      latest_tag := get_latest_tag(root_url)
      if latest_tag != "" {
        project.version = latest_tag  // update version only
        println("Updated $project.name to version $latest_tag")
      } else {
        println("No tags found for $project.name")
      }
    } else {
      println("No root URL found for $project.name")
    }
  }

  // Write updated pkglist back to disk
  updated_json := json.encode_pretty(pkglist_json)
  os.write_file("pkglist.json", updated_json) or { eprintln("Failed to write updated pkglist.json: $err") }
}

fn get_latest_tag(repo_url string) string {
    cmd := 'git ls-remote --tags $repo_url | awk -F/ \'{print \$NF}\' \
        | grep -Eo \'[0-9]+([._][0-9]+){1,2}\' \
        | sed \'s/_/./g\' \
        | sort -t. -k1,1n -k2,2n -k3,3n \
        | tail -n1'
    result := os.execute('bash -c "$cmd"')
    return result.output.trim_space()
}
