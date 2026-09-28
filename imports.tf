# Adopt records created during bootstrap so the next OpenTofu apply owns them
# instead of attempting to create a duplicate.
import {
  to = cloudflare_dns_record.tunnel["quiz"]
  id = "0314cb864c6d8959ce5b26555c516d70/7f5e043ba7d182f9d58b63a7602521f0"
}
