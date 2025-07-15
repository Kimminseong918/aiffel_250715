-- SELECT *
-- FROM `modulabs-project-465602.250715_project.amazon` LIMIT 1000

--추천 시스템 1
--추천 시스템 이름: 품질까지 1등! 가성비가 최고다!
--추천 시스템 테마: 구매자의 경제적 이득을 목표로 가장 높은 할인율을 가지는 제품 추천한다.
  --할인율만 높은 것이 아닌, 일정 수준 이상의 평점, 리뷰수를 가진 제품 선정하여 품질도 보장할 수 있다.
  --즉, 높은 품질의 제품을 가장 저렴하게 구매할 수 있는 기회 제공

--구현 로직
-- WITH ProcessedData AS (
--   SELECT
--     product_name,
--     category,
--     discounted_price,
--     actual_price,
--     --할인율 % 제외, 숫자 변환
--     ROUND(CAST(REPLACE(CAST(discount_percentage AS STRING), '%' , '') AS FLOAT64)) AS discount_percent,
--     --평점 숫자 변환
--     SAFE_CAST(rating AS FLOAT64) AS rating_value,
--     CAST(REPLACE(CAST(rating_count AS STRING), ',' , '') AS INT64) AS review_count,
--     product_link
--   FROM
--     `modulabs-project-465602.250715_project.amazon`)
-- SELECT
--   product_name AS product_name,
--   category AS category,
--   discounted_price AS discounted_price,
--   actual_price AS actual_price,
--   discount_percent AS discount_percent,
--   rating_value AS rating,
--   review_count AS review_count,
--   product_link AS product_link
-- FROM
--   ProcessedData
-- WHERE --평점 4.0 이상, 리뷰 100개 이상
--   rating_value >= 4.0
--   AND review_count >= 100
-- ORDER BY --할인율 높은 순서로 정렬
--   discount_percent DESC
-- LIMIT 100;





--추천 시스템 2
--추천 시스템 이름: 카테고리별 인기 상품 추천
--추천 시스템 테마: 전체 인기 상품 추천이 아닌, 각 카테고리별 인기 상품 상위 3개를 추천한다
  --소비자는 관심 있는 카테고리에서 인기 상품만 빠르게 찾을 수 있어 시간을 줄여주고 신뢰감을 준다
  --인기도 점수 = 평점 * 리뷰 수 
  --ROW_NUMBER()로 인기도 점수가 높은 순으로 순위 매겨서 상위 3개 추천

--구현 로직
-- WITH ProcessedData AS (
--   SELECT
--     product_name,
--     category,
--     SAFE_CAST(rating AS FLOAT64) AS rating_value,
--     CAST(REPLACE(CAST(rating_count AS STRING), ',' , '') AS INT64) AS review_count,
--     product_link,
--     -- 인기도 점수= 평점 * log(리뷰 수)
--     SAFE_CAST(rating AS FLOAT64) * LOG(CAST(REPLACE(CAST(rating_count AS STRING), ',' , '') AS INT64)) AS popularity_score
--   FROM
--     `modulabs-project-465602.250715_project.amazon`
-- ), RankedProducts AS (
--   SELECT *,
--     ROW_NUMBER() OVER(PARTITION BY category ORDER BY popularity_score DESC) AS category_rank
--   FROM
--     ProcessedData)
-- SELECT
--   category AS category,
--   category_rank AS category_rank,
--   product_name AS product_name,
--   rating_value AS rating,
--   review_count AS review_count,
--   product_link AS product_link
-- FROM
--   RankedProducts
-- WHERE
--   category_rank <= 3
-- ORDER BY
--   category, category_rank;





--추천 시스템 3
--추천 시스템 이름: 얼리어답터에게 신상!!! 추천
--추천 시스템 테마: 최신 기술 반영이 중요한 'Computers & Accessories', 'Electronics' 카테고리에서 상대적으로 리뷰 수는 적지만 높은 평점을 받아 초기 구매자에게 높은 평점을 받는 신상 제품 추천
  --특히 'Computers & Accessories', 'Electronics'에 많을 얼리어답터 특성의 구매자 타겟팅
  --좋은 신상 > 적은 리뷰 수, 높은 평점

--구현 로직
-- WITH ProcessedData AS (
--   SELECT
--     product_name,
--     category,
--     --평점 숫자 변환
--     SAFE_CAST(rating AS FLOAT64) AS rating_value,
--     --쉼표 제거
--     SAFE_CAST(REPLACE(CAST(rating_count AS STRING), ',' , '') AS INT64) AS review_count,
--     about_product,
--     product_link
--   FROM
--     `modulabs-project-465602.250715_project.amazon`
-- )
-- SELECT
--   product_name,
--   category,
--   rating_value AS rating,
--   review_count,
--   about_product,
--   product_link
-- FROM
--   ProcessedData
-- WHERE
-- --해당 카테고리 선별
--   (category LIKE '%Computers&Accessories%' OR category LIKE '%Electronics%')
--   --평점 4.4 이상
--   AND rating_value >= 4.4
--    --리뷰 수 50개 이상 1000개 이하 제품
--   AND review_count BETWEEN 50 AND 1000
-- ORDER BY
-- --평점 높은 순 > 리뷰 많은 순 정렬
--   rating_value DESC, review_count DESC
-- LIMIT 50;





--추천 시스템 4
--추천 시스템 이름: 숨은 맛집 추천
--추천 시스템 테마: 리뷰 수는 적어 상대적으로 많은 사람이 이용하는 상품은 아니지만 리뷰 내용에 긍정적 키워드가 많이 포함된 제품 추천
  --대중적인 제품보다는 소수만 아는 제품을 이용하고자 하는 구매자 타겟팅
  --리뷰 수가 50개 미만인 제품 중, 긍정 키워드 횟수 계산

--구현 로직
-- --1. 리뷰 수 숫자로 변환
-- WITH ProcessedData AS (
--   SELECT
--     product_id,
--     product_name,
--     category,
--     review_content,
--     CAST(REPLACE(CAST(rating_count AS STRING), ',', '') AS INT64) AS rating_count,
--     product_link
--   FROM
--     `modulabs-project-465602.250715_project.amazon`
--   WHERE
--     rating_count IS NOT NULL
--     AND review_content IS NOT NULL
-- ),

-- --2. 긍정 키워드 계산
-- PositiveKeywordCount AS (
--   SELECT
--     product_id,
--     --긍정단어가 몇개 나왔는지 횟수 세기
--     --(본 문장) - (해당 긍정 단어를 제외한 문장) = 나온 길이 / 단어 길이 > 몇번 단어가 나왔는지 알 수 있다
--     (
--       (LENGTH(LOWER(review_content)) - LENGTH(REPLACE(LOWER(review_content), 'great', ''))) / LENGTH('great') +
--       (LENGTH(LOWER(review_content)) - LENGTH(REPLACE(LOWER(review_content), 'love', ''))) / LENGTH('love') +
--       (LENGTH(LOWER(review_content)) - LENGTH(REPLACE(LOWER(review_content), 'perfect', ''))) / LENGTH('perfect') +
--       (LENGTH(LOWER(review_content)) - LENGTH(REPLACE(LOWER(review_content), 'excellent', ''))) / LENGTH('excellent')
--     ) AS keyword_score
--   FROM
--     ProcessedData
--   WHERE
--     rating_count > 0 AND rating_count < 50
-- ), AggScores AS (
--   SELECT
--     product_id,
--     --total score: 긍정 키워드가 몇번 나왔는가
--     SUM(keyword_score) AS total_score 
--   FROM
--     PositiveKeywordCount
--   GROUP BY
--     product_id
-- )
-- --3. 점수가 있는 정보만 출력
-- SELECT
--   p.product_name,
--   p.category,
--   p.rating_count,
--   agg.total_score,
--   p.product_link
-- FROM
--   ProcessedData AS p
-- JOIN
--   AggScores AS agg
--   ON p.product_id = agg.product_id
-- WHERE
--   agg.total_score > 0
-- GROUP BY
--   p.product_name,
--   p.category,
--   p.rating_count,
--   agg.total_score,
--   p.product_link
-- ORDER BY
--   agg.total_score DESC, p.rating_count DESC






--추천 시스템 5
--추천 시스템 이름: 사용자 기반 협업 필터링
--추천 시스템 테마: 특정 제품을 좋아하는 구매자는 다른 제품도 좋아하는가를 분석한다
  --내가 좋게 평가한 제품과 같은 평가를 내린 타 구매자의 다른 구매 상품에는 어떤 것이 있는지 추천하는 시스템이다
  --구매자에게 비슷한 구매자의 선택을 보여줌으로 좀더 개인화된 선택과 직관적인 추천 가능하다
  --개별 제품의 속성이 아닌, 사용자와 사용자 간의 관계를 분석

--구현 로직
-- --기준 제품: B07JW9H4J1
-- --SimilarUsers: 기준 제품을 좋아하는 사용자 목록

-- WITH SimilarUsers AS (
--   SELECT DISTINCT
--     user_id
--   FROM
--     `modulabs-project-465602.250715_project.amazon`
--   WHERE
--     REGEXP_CONTAINS(rating, r'^\d+(\.\d+)?$') --특수문자가 섞여있을 경우 오류 방지
--     AND product_id = 'B07JW9H4J1'
--     AND CAST(rating AS FLOAT64) >= 4.0 --평점 4.0 이상 매긴 사용자 필터링
--     AND user_id IS NOT NULL),
-- --기준 제품을 좋게 평가한 사용자들이 좋아한 다른 제품들
-- Recommendations AS (
--   SELECT
--     t.product_id,
--     t.product_name,
--     t.category,
--     t.product_link
--   FROM
--     `modulabs-project-465602.250715_project.amazon` AS  t 
--   JOIN
--     SimilarUsers s ON t.user_id = s.user_id
--   WHERE
--     REGEXP_CONTAINS(t.rating, r'^\d+(\.\d+)?$')
--     AND t.product_id != 'B07JW9H4J1' 
--     --기준 제품은 목록에서 제외한다
--     AND CAST(t.rating AS FLOAT64) >= 4.0 
--     --평가 기준은 4.0으로 동일, 다른 제품도 4.0 이상이면 필터링
-- )
-- SELECT
--   r.product_name AS `추천 제품명`,
--   r.category AS `카테고리`,
--   --추천점수
--   --비숫한 사용자 그룹에서 각 제품에 몇번 등장 했는가 카운팅
--   --높을수록 많은 사람이 (비슷한 사람이) 구매한 제품이다 > 신뢰도가 높은 물품이다
--   COUNT(r.product_id) AS recommendation_score,
--   ANY_VALUE(r.product_link) AS `제품_링크`
-- FROM
--   Recommendations AS r
-- GROUP BY
--   r.product_name, r.category
-- ORDER BY
--   recommendation_score DESC;