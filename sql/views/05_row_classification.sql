CREATE OR REPLACE VIEW row_classification AS
SELECT
    fc.*,

    CASE
        WHEN COALESCE(TRIM(col01), '') = ''
         AND COALESCE(TRIM(col02), '') = ''
         AND COALESCE(TRIM(col03), '') = ''
         AND COALESCE(TRIM(col04), '') = ''
         AND COALESCE(TRIM(col05), '') = ''
         AND COALESCE(TRIM(col06), '') = ''
         AND COALESCE(TRIM(col07), '') = ''
         AND COALESCE(TRIM(col08), '') = ''
         AND COALESCE(TRIM(col09), '') = ''
         AND COALESCE(TRIM(col10), '') = ''
            THEN 'blank'

        WHEN LOWER(TRIM(col01)) IN ('date', 'transaction date', 'posted date')
          OR LOWER(TRIM(col02)) IN ('date', 'transaction date', 'description', 'amount')
          OR LOWER(TRIM(col03)) IN ('amount', 'debit', 'credit')
            THEN 'header'

        ELSE 'transaction'
    END AS row_classification,

    CASE
        WHEN COALESCE(TRIM(col01), '') = ''
         AND COALESCE(TRIM(col02), '') = ''
         AND COALESCE(TRIM(col03), '') = ''
         AND COALESCE(TRIM(col04), '') = ''
         AND COALESCE(TRIM(col05), '') = ''
         AND COALESCE(TRIM(col06), '') = ''
         AND COALESCE(TRIM(col07), '') = ''
         AND COALESCE(TRIM(col08), '') = ''
         AND COALESCE(TRIM(col09), '') = ''
         AND COALESCE(TRIM(col10), '') = ''
            THEN 'all parsed columns are blank'

        WHEN LOWER(TRIM(col01)) IN ('date', 'transaction date', 'posted date')
          OR LOWER(TRIM(col02)) IN ('date', 'transaction date', 'description', 'amount')
          OR LOWER(TRIM(col03)) IN ('amount', 'debit', 'credit')
            THEN 'row appears to contain header labels'

        ELSE NULL
    END AS row_classification_reason,

    CASE
        WHEN
            CASE
                WHEN COALESCE(TRIM(col01), '') = ''
                 AND COALESCE(TRIM(col02), '') = ''
                 AND COALESCE(TRIM(col03), '') = ''
                 AND COALESCE(TRIM(col04), '') = ''
                 AND COALESCE(TRIM(col05), '') = ''
                 AND COALESCE(TRIM(col06), '') = ''
                 AND COALESCE(TRIM(col07), '') = ''
                 AND COALESCE(TRIM(col08), '') = ''
                 AND COALESCE(TRIM(col09), '') = ''
                 AND COALESCE(TRIM(col10), '') = ''
                    THEN 'blank'

                WHEN LOWER(TRIM(col01)) IN ('date', 'transaction date', 'posted date')
                  OR LOWER(TRIM(col02)) IN ('date', 'transaction date', 'description', 'amount')
                  OR LOWER(TRIM(col03)) IN ('amount', 'debit', 'credit')
                    THEN 'header'

                ELSE 'transaction'
            END = 'transaction'
        THEN TRUE
        ELSE FALSE
    END AS is_transaction_row

FROM file_context fc;
