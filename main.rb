#main.rb
#Takes in file containing list of server to connect to.
#Outputs text map
#Summon graphviz
#
require 'net/ssh'
require 'pathname'
require 'fileutils'
#Class for nodes?

hosts_ary = Array.new
system 'mkdir', '-p', 'out_files'
system 'mkdir', '-p', 'images'

File.open("in_file", "r") do |ifile|
    ifile.each_line do |hostname|
        hostname.chomp!                                     #Net:SSH seems to be very picky about newlines and whitespace in its hostnames
        hosts_ary.push(hostname)

        Net::SSH.start( hostname, 'ejolsen' ) do |session|
            server_output = session.exec!("mount")          #capture output of mount from remote host
            filename="out_files/"+hostname+".gv"

            if File.exist?("#{filename}") then
                File.delete("#{filename}")                  #IF file exists, delete it, if not, proceed as normal
            end

            ofile = File.open(filename, "a+")
            ofile << "digraph G {\n"

            server_output.each_line do |mountline|
                if mountline =~ /^nfs\./                    #parse for nfs mount lines
                    splitary=mountline.split
                    storage_point=splitary[0]
                    local_point=splitary[2]
                    ofile << '"'+hostname+'"'+" -> "+'"'+local_point+'"'+" -> "+'"'+storage_point+'"'+"\n"
                end
            end
            ofile << "}\n"
            ofile.close

        end
    end
ifile.close
end

hosts_ary.each do |hosts| 
    system "dot", "-Tpng", "out_files/#{hosts}.gv", "-o", "images/#{hosts}.png"
end
