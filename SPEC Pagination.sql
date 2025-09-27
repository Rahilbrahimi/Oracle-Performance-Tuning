/*********************************************************************
 * PACKAGE: pagination_pkg_opt_new_version
 *
 * This package provides utilities for paginating JSON data stored as CLOB.
 * It supports extracting offset and limit from SQL queries, validating inputs,
 * slicing JSON arrays, building pagination links, and generating paginated JSON responses.
 *********************************************************************/

Create or REPLACE PACKAGE ORDS.pagination_pkg_opt_new_version as 
 
/**
 *validate that the given offset is not negative.
 *@param p_offset offset value to validate
 *@raises value_error if the offset is negative
 */
procedure validate_offset(p_oofset IN number) ;

/**
 *Validate that the given limit is greater than zero.
 *@param p_limit Limit value to validate
 *@raised value_error if the limit is less than 1
 */

procedure validate_limit(p_limit in number);

  /**
     * Entry point for pagination logic.
     * This procedure can include calls to other internal functions such as:
     * - get_uri_base_path
     * - get_uri_path
     * - get_query_param
     * - extract_offset_limit_from_url
     * - count_items
     * - has_next_page
     * - total_count
     * - remove_last_element
     * - build_pagination_links
     * - get_paginated_data_from_clob
     *
     * @param p_data        JSON data as CLOB
     * @param p_offset      Starting offset
     * @param p_limit       Number of items per page
     * @param p_total_count Total number of items (optional)
     */
procedure run(
   p_Data in clob,
   p_offset in number,
   p_limit in number,
   p_total_count in number
);

end pagination_pkg_opt_new_version;
/
    
