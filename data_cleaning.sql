-- Limpeza dos Dados

SELECT *
FROM layoffs;

/** Etapas do Processo **/
-- 1. Remover duplicados
-- 2. Padronizar os dados
-- 3. Valores Null ou vazios
-- 4. Remover colunas

-- Criando uma tabela idêntica para realizar o trabalho, mantendo a original intacta
CREATE TABLE layoffs_staging
LIKE layoffs;

-- Copiando os dados para a nova tabela
INSERT layoffs_staging
SELECT *
FROM layoffs;

/** 1.Removendo duplicados **/
-- Vamos utilizar ROW_NUMBER para averiguar se há dados duplicados
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;


-- Seria útil fazer queries sobre o resultado acima. Vamos utilizar CTEs
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Criando uma segunda tabela intermediaria para deletar os duplicados


CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


SELECT *
FROM layoffs_staging2;

-- Inserindo os dados na nova tabela
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Deletando os duplicados
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

/** 2. Padronizando os dados **/

SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- Tem 3 entradas para Crypto

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- Padronizando todas as entradas para somenete 'Crypto'
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';


-- Alguns dados em 'country' estão como 'United States.'
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Mundando 'date' de texto para formato data, temos que usar STR_TO_DATE primeiro

SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

SELECT `date`
FROM layoffs_staging2;

-- no entanto a coluna 'date' ainda esta como texto, temos que mudar para data
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

/** 3. Removendo valores Nulls e Vazios(blank) **/

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';


SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- Algumas entradas possuem 'location' mas tem o campo 'industry' vazio, porem as mesmas empresas possuem estes campos populados em outras entradas
SELECT t1.company, t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- Mudar os espaços vazios para NULL vai facilitar a substituição
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

SELECT *
FROM layoffs_staging2;


-- Deletando entradas em que total_laid_off e percentage_laid_off é NULL (361 rows)
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2;

/** Deletando colunas **/

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging2;

