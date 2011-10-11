description = [[
Scrapes the secondary namenode status page.  

information gathered:
 * Date/Time the service was started
 * Hadoop Version
 * Hadoop Complie date
 * Upgrades status
 * Filesystem Directory (reletive to the http://host:port/)
 * Log Directory (reletive to the http://host:port/)
 * Associated Datanodes
 
For more information about Hadoop, see:
 * http://hadoop.apache.org/
 * http://en.wikipedia.org/wiki/Apache_Hadoop
]]

---
-- @usage
-- nmap --script  hadoop-secondary-namenode-info -p 50090 host
--
-- @output
-- PORT      STATE SERVICE         REASON
-- 50070/tcp open   hadoop-secondary-namenode syn-ack
-- | hadoop-namenode-info: 
-- |   Started:  Wed May 11 22:33:44 PDT 2011
-- |   Version:  0.20.2-cdh3u1, f415ef415ef415ef415ef415ef415ef415ef415e
-- |   Compiled:  Wed May 11 22:33:44 PDT 2011 by bob from unknown
-- |   Upgrades:  There are no upgrades in progress.
-- |   Filesystem: /nn_browsedfscontent.jsp
-- |   Logs: /logs/
-- |   Storage:
-- |   Total       Used (DFS)      Used (Non DFS)  Remaining
-- |   100 TB      85 TB           500 GB          14.5 TB
-- |   Datanodes (Live): 
-- |     Datanode: datanode1.example.com:50075
-- |     Datanode: datanode2.example.com:50075
---


author = "john.r.bond@gmail.com"
license = "Simplified (2-clause) BSD license--See http://nmap.org/svn/docs/licenses/BSD-simplified"
categories = {"default", "discovery", "safe"}

require ("shortport")
require ("target")
require ("http")

portrule = shortport.port_or_service ({50090}, "hadoop-secondary-namenode", {"tcp"})

action = function( host, port )

        local result = {}
	local uri = "/status.jsp"
	stdnse.print_debug(1, ("%s:HTTP GET %s:%s%s"):format(SCRIPT_NAME, host.targetname or host.ip, port.number, uri))
	local response = http.get( host.targetname or host.ip, port.number, uri )
	stdnse.print_debug(1, ("%s: Status %s"):format(SCRIPT_NAME,response['status-line']))  
	if response['status-line']:match("200%s+OK") and response['body']  then
		local body = response['body']:gsub("%%","%%%%")
		local stats = {}
		stdnse.print_debug(2, ("%s: Body %s\n"):format(SCRIPT_NAME,body))  
		port.version.name = "hadoop-secondary-namenode"
                port.version.product = "Apache Hadoop"
		-- Page isn't valid html :(
		if body:match("Version:%s*</td><td>([^][\n]+)") then
			local version = body:match("Version:%s*</td><td>([^][\n]+)")
			stdnse.print_debug(1, ("%s: Version %s"):format(SCRIPT_NAME,version))  
			table.insert(result, ("Version: %s"):format(version))
			port.version.version = version
		end
		if body:match("Compiled:%s*</td><td>([^][\n]+)") then
			local compiled = body:match("Compiled:%s*</td><td>([^][\n]+)")
			stdnse.print_debug(1, ("%s: Compiled %s"):format(SCRIPT_NAME,compiled))  
			table.insert(result, ("Compiled: %s"):format(compiled))
		end
                for i in string.gmatch(body,"\n[%w%s]+:%s+[^][\n]+") do
			table.insert(stats,i:match(":%s+([^][\n]+)"))
		end
		stdnse.print_debug(1, ("%s: namenode %s"):format(SCRIPT_NAME,stats[1]))
		stdnse.print_debug(1, ("%s: Start %s"):format(SCRIPT_NAME,stats[2]))
		stdnse.print_debug(1, ("%s: Last Checkpoint %s"):format(SCRIPT_NAME,stats[3]))
		stdnse.print_debug(1, ("%s: Checkpoint Period %s"):format(SCRIPT_NAME,stats[4]))
		stdnse.print_debug(1, ("%s: Checkpoint Size %s"):format(SCRIPT_NAME,stats[5]))
		table.insert(result, ("namenode %s"):format(stats[1]))
		table.insert(result, ("Start %s"):format(stats[2]))
		table.insert(result, ("Last Checkpoint %s"):format(stats[3]))
		table.insert(result, ("Checkpoint Period %s"):format(stats[4]))
		table.insert(result, ("Checkpoint Size %s"):format(stats[5]))
		if target.ALLOW_NEW_TARGETS then
			if stats[1]:match("([^][/]+)") then
				local newtarget = stats[1]:match("([^][/]+)")
				stdnse.print_debug(1, ("%s: Added target: %s"):format(SCRIPT_NAME, newtarget))
				local status,err = target.add(newtarget)
			end
		end
		
	end
	return stdnse.format_output(true, result)
end