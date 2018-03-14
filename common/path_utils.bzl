# Copyright 2017 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Support functions common path operations."""

load("@bazel_skylib//lib:paths.bzl",
     "paths")


def _bundle_relative_path(f):
  """Returns the portion of `f`'s path relative to its containing `.bundle`.

  This function fails if `f` does not have an ancestor directory named with the
  `.bundle` extension.

  Args:
    f: A file.
  Returns:
    The `.bundle`-relative path to the file.
  """
  return paths.relativize(
      f.short_path, _farthest_directory_matching(f.short_path, "bundle"))


def _farthest_directory_matching(path, extension):
  """Returns the part of a path with the given extension closest to the root.

  For example, if `path` is `"foo/bar.bundle/baz.bundle"`, passing `".bundle"`
  as the extension will return `"foo/bar.bundle"`.

  Args:
    path: The path.
    extension: The extension of the directory to find.
  Returns:
    The portion of the path that ends in the given extension that is closest
    to the root of the path.
  """
  prefix, ext, _ = path.partition("." + extension)
  if ext:
    return prefix + ext

  fail("Expected path %r to contain %r, but it did not" % (
      path, "." + extension))


def _owner_relative_path(f):
  """Returns the portion of `f`'s path relative to its owner.

  Args:
    f: A file.
  Returns:
    The owner-relative path to the file.
  """
  if f.is_source:
    # Even though the docs says a File's `short_path` doesn't include the
    # root, Bazel special cases anything that is external and includes a
    # relative path (../) to the file. On the File's `owner` we can get the
    # `workspace_root` to try and line things up, but it is in the form of
    # "external/[name]". However the File's `path` does include the root and
    # leaves it in the "externa/" form.
    return paths.relativize(f.path,
                            paths.join(f.owner.workspace_root, f.owner.package))
  else:
    return paths.relativize(f.short_path, f.owner.package)


# Define the loadable module that lists the exported symbols in this file.
path_utils = struct(
    bundle_relative_path=_bundle_relative_path,
    owner_relative_path=_owner_relative_path,
)
