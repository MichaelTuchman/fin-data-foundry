SELECT canonical_field, count(*)
FROM canon_long
GROUP BY 1
ORDER BY 1;
