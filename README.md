# r-dhis2-mer-data-import
This  tool is intended to read DATIM MER indicators from excell files and upload them to DHIS2.The DATIM data elements and categoryoptioncombos are mapped with the CCS DHIS data dictionary through the following excell templates located under the /mapping dir
<ul>
  <li>MER CARE AND TREATMENT.xlsx</li>
  <li>MER SMI.xlsx</li>
  <li>MER ATS.xlsx</li>
   <li>MER PREVENTION.xlsx</li>  
   <li>MER HEALLTH SYSTEMS.xlsx </li>
   <li>MER COMMUNITY.xlsx </li>
</ul>   </br>
Data import into CCS DHIS2 is done using  <a href="https://docs.dhis2.org/en/develop/using-the-api/dhis-core-version-237/introduction.html"> DHIS2 WEB API </a>.

<h3>  1- Clone project </h3>
 $ git clone https://github.com/crysiscore/r-dhis2-mer-data-import.git

 <h3> 2 - Create  needed dirs and files on hosting server  </h3>
 $ mkdir -p  /data_ssd_1/shiny-apps/dhis/apps  - Store app files here
 $ mkdir -p  /data_ssd_1/shiny-apps/dhis/history          ->  Story upload history here
 $ mkdir -p  /data_ssd_1/shiny-apps/dhis/history/mensal   ->  monthly upload
 $ mkdir -p  /data_ssd_1/shiny-apps/dhis/history/datim    ->  quarterly/semi-anuall upload
 $ cp r-dhis2-mer-data-import/dataset_templates/template_errors.xlsx  /data_ssd_1/shiny-apps/dhis/history/
 $cp r-dhis2-mer-data-import/dataset_templates/DHIS2 UPLOAD HISTORY.xlsx /data_ssd_1/shiny-apps/dhis/history/

 <h3> 3- Create credentials.R file inside root dir r-dhis2-mer-data-import and write the following variables :
   dhis2.password =''
   dhis2.password=''  </h3>
 $ touch r-dhis2-mer-data-import/credentials.R

 <h3> 4- Copy  r-dhis2-mer-data-import  to apps dir and give it any name  </h3>
  $ cp -r r-dhis2-mer-data-import /data_ssd_1/shiny-apps/dhis/apps/datim-app

<h3> 5- Give read and write permission to all dir </h3>
  $ sudo  chmod -R 777  /data_ssd_1/shiny-apps/dhis/apps
  $ sudo  chmod -R 777  /data_ssd_1/shiny-apps/dhis/history


<h3> 6 - Create a docker shiny-server  container : image https://hub.docker.com/repository/docker/crysiscore/shiny-server/general  , hiny-server listen on port 3838 by default</h3>

$ docker run -d --name shiny-server -p5460:3838 -v /data_ssd_1/shiny-apps/dhis/history:/uploads -v /data_ssd_1/shiny-apps/dhis/apps:/srv/shiny-server/ crysiscore/shiny-server:1.0


<h3> 8- Access the app through the host_ip and port server-ip:5460/app-name </h3>


</h3> In case of new  data elements/ categoryoption combos  on DATIM,  follow instructions to update the config files on report_generator.R file</h3>

