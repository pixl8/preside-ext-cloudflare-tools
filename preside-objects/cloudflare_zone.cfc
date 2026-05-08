/**
 * @labelField             domain
 * @versioned              false
 * @dataManagerEnabled     true
 * @dataManagerGridFields  domain,zone_name,zone_id,not_found
 */

component {
	property name="domain"    type="string"  dbtype="varchar" maxlength=255 required=true uniqueindexes="domain";
	property name="zone_id"   type="string"  dbtype="varchar" maxlength=50;
	property name="zone_name" type="string"  dbtype="varchar" maxlength=255;
	property name="not_found" type="boolean" dbtype="boolean" default=false;
}