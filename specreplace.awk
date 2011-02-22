# Awk script for replacing @name@, @version@ and @release@ in a file. The script
# is used in .spec.in-files before building rpm-files.
{
  if ( length(name) == 0 ||
       length(version) == 0 ||
       length(release) == 0 ) {
    printf "Awk-problem: Variables name, version and release must not be empty.\n"
    printf "             Length of either name, version or release is 0.\n"
    exit 1;
  } else {
    gsub(/@name@/,name);
    gsub(/@version@/,version);
    gsub(/@release@/,release);
    print
  }
}
