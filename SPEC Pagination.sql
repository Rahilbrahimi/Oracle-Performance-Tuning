/*********************************************************************
 * PACKAGE: pagination_pkg_opt_new_version
 *
 * This package provides utilities for paginating JSON data stored as CLOB.
 * It supports extracting offset and limit from SQL queries, validating inputs,
 * slicing JSON arrays, building pagination links, and generating paginated JSON responses.
 *********************************************************************/

/**
 * this package new version by update_url.
 */
 

CREATE OR REPLACE PACKAGE pagination_pkg_opt_new_version AS
    /**
     * Default starting offset used when not provided in the URL.
     */
    DEFAULT_OFFSET CONSTANT PLS_INTEGER := 0;

    /**
     * Default limit for number of items per page when not provided in the URL.
     */
    DEFAULT_LIMIT  CONSTANT PLS_INTEGER := 100;

    /**
     * Validates that the given offset is not negative.
     *
     * @param p_offset Offset value to validate.
     * @raises PAGINATION_OFFSET_ERR if the offset is negative.
     */
    PROCEDURE validate_offset(p_offset IN NUMBER);

    /**
     * Validates that the given limit is greater than zero.
     *
     * @param p_limit Limit value to validate.
     * @raises PAGINATION_LIMIT_ERR if the limit is less than 1.
     */
    PROCEDURE validate_limit(p_limit IN NUMBER);

    /**
     * Updates a URL by replacing offset and limit query parameters if they exist.
     *
     * @param p_url    Original URL to modify.
     * @param p_offset Offset value to embed.
     * @param p_limit  Limit value to embed.
     * @return Updated URL string.
     */
    FUNCTION update_url_with_pagination(
        p_url    IN VARCHAR2,
        p_offset IN NUMBER,
        p_limit  IN NUMBER
    ) RETURN VARCHAR2;

    /**
     * Extracts offset and limit from the provided URL query string.
     *
     * @param p_url            URL containing the query parameters.
     * @param p_offset         OUT parameter to store the extracted offset.
     * @param p_limit          OUT parameter to store the extracted limit.
     * @param p_default_offset Default offset value if not found in URL.
     * @param p_default_limit  Default limit value if not found in URL.
     */
    PROCEDURE extract_offset_limit_from_url(
        p_url            IN VARCHAR2,
        p_offset         OUT NUMBER,
        p_limit          OUT NUMBER,
        p_default_offset IN NUMBER DEFAULT DEFAULT_OFFSET,
        p_default_limit  IN NUMBER DEFAULT DEFAULT_LIMIT
    );

    /**
     * Counts the number of elements in a given JSON array.
     *
     * @param p_data JSON_ARRAY_T object to count.
     * @return Number of elements in the array.
     */
    FUNCTION count_items(p_data JSON_ARRAY_T) RETURN NUMBER;

    /**
     * Determines whether there is another page after the current one.
     *
     * @param p_offset Current offset.
     * @param p_limit  Current limit.
     * @param p_total  Total number of available items.
     * @return TRUE if more pages exist, otherwise FALSE.
     */
    FUNCTION has_next_page(p_offset IN NUMBER, p_limit IN NUMBER, p_total IN NUMBER) RETURN BOOLEAN;

    /**
     * Removes the last element from a JSON array.
     *
     * @param p_data JSON_ARRAY_T object to modify.
     */
    PROCEDURE remove_last_element(p_data IN OUT NOCOPY JSON_ARRAY_T);

    /**
     * Builds a JSON array of pagination links (self, first, previous, next, last).
     *
     * @param p_path   Base path or URL.
     * @param p_offset Current offset.
     * @param p_limit  Current limit.
     * @param p_total  Total number of available items.
     * @return JSON_ARRAY_T containing pagination link objects.
     */
    FUNCTION build_pagination_links(
        p_path   IN VARCHAR2,
        p_offset IN NUMBER,
        p_limit  IN NUMBER,
        p_total  IN NUMBER
    ) RETURN JSON_ARRAY_T;

    /**
     * Paginates JSON data given as a CLOB and returns a CLOB containing
     * paginated results with metadata.
     *
     * @param p_json_clob CLOB containing JSON array of data.
     * @param p_path      Base path or URL for pagination links (default: /api/v1/data).
     * @return CLOB containing JSON object with "data" and "pagination" info.
     */
    FUNCTION get_paginated_data_from_clob(
        p_json_clob IN CLOB,
        p_path      IN VARCHAR2 DEFAULT '/api/v1/data'
    ) RETURN CLOB;

END pagination_pkg_opt_new_version;
/
