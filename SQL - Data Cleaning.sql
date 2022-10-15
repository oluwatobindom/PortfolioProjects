/*
Cleaning Nashville Housing Data using SQL Queries
Skills used : CREATE, UPDATE, SELECT, CTE, JOINS, ORDER BY, GROUP BY
-- The dataset is available on https://www.kaggle.com/tmthyjames/nashville-housing-data
*/


SELECT *
FROM 
	PortfolioProject..NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

--1. Standardizing SaleDate Format
----- Convert SaleDate from datetime to date as time does not serve any purpose here
----- Update NashvilleHousing table with converted datatype values
----- Option 1:

SELECT 
	SaleDate, 
	CONVERT(Date,SaleDate)
FROM 
	PortfolioProject..NashvilleHousing


UPDATE PortfolioProject..NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

-- If SaleDate does not Update properly
----- Work-around 'CONVERT and UPDATE method' as sometimes SQL Server does update table as queried 
----- Option 2:

SELECT
	SaleDateConverted --CONVERT(Date,SaleDate)
FROM
	PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
ADD SaleDateConverted Date;

UPDATE PortfolioProject..NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)


 --------------------------------------------------------------------------------------------------------------------------

--2. Populating Property Address data 
----- Each Property Address has a unique ParcelID
----- Using selfjoin, we can then populate PropertyAddress column where PropertyAddress IS NULL

SELECT *
FROM 
	PortfolioProject..NashvilleHousing
--Where PropertyAddress IS NULL
ORDER BY
	ParcelID



-- Using Self Join to extract addresses based on ParcelID
SELECT 
	NH.ParcelID, 
	NH.PropertyAddress, 
	NH2.ParcelID, 
	NH2.PropertyAddress, 
	ISNULL(NH.PropertyAddress, NH2.PropertyAddress)
FROM 
	PortfolioProject..NashvilleHousing AS NH
JOIN PortfolioProject..NashvilleHousing AS NH2
	ON	NH.ParcelID = NH2.ParcelID
	AND NH.[UniqueID ] <> NH2.[UniqueID ]
WHERE 
	NH.PropertyAddress IS NULL


-- Updating Null values with extracted addresses
UPDATE NH
SET 
	PropertyAddress = ISNULL(NH.PropertyAddress,NH2.PropertyAddress)
FROM 
	PortfolioProject..NashvilleHousing AS NH
JOIN PortfolioProject..NashvilleHousing AS NH2
	ON NH.ParcelID = NH2.ParcelID
	AND NH.[UniqueID ] <> NH2.[UniqueID ]
WHERE 
	NH.PropertyAddress IS NULL




--------------------------------------------------------------------------------------------------------------------------

--3. Breaking out the columns with Addresses into Individual Columns of (Address, City, State)
-----[A] PropertyAddress
----- The only Delimiter in the PropertyAddress column is a single comma
----- Splitting address using SUBSTRING & CHARINDEX

SELECT
	PropertyAddress
FROM
	PortfolioProject..NashvilleHousing
--WHERE PropertyAddress IS NULL
--ORDER BY ParcelID


SELECT
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) AS PropertyAddressOnly,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) AS PropertyCityOnly
FROM
	PortfolioProject..NashvilleHousing


-- Property Address Only
ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertyAddressOnly Nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET PropertyAddressOnly = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )


-- Property City Only
ALTER TABLE PortfolioProject..NashvilleHousing
Add PropertyCityOnly Nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET PropertyCityOnly = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))







-----[B] OwnerAddress
----- The OwnerAddress column has two commas as delimiters
----- Splitting address using PARSENAME & REPLACE
SELECT
	OwnerAddress
FROM
	PortfolioProject..NashvilleHousing


SELECT
	PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3) AS OwnerAddressOnly,
	PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2) AS OwnerCityOnly,
	PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1) AS OwnerStateOnly
FROM
	PortfolioProject..NashvilleHousing


-- Owner's Adress Only
ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerAddressOnly Nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerAddressOnly = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


-- Owner's City Only
ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerCityOnly Nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerCityOnly = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)


-- Owner's State Only
ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerStateOnly Nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerStateOnly = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)






--------------------------------------------------------------------------------------------------------------------------


--4. Changing Y and N to Yes and No in "Sold as Vacant" field


SELECT
	DISTINCT(SoldAsVacant), 
	COUNT(SoldAsVacant)
FROM
	PortfolioProject..NashvilleHousing
GROUP BY
	SoldAsVacant
ORDER BY 2




SELECT 
	SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM
	PortfolioProject..NashvilleHousing


UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END





-----------------------------------------------------------------------------------------------------------------------------------------------------------

--5. Removing Duplicates
----- Showing the duplicate rows
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
						) AS row_num

FROM
	PortfolioProject..NashvilleHousing
--order by ParcelID
					)
SELECT *
FROM
	RowNumCTE
WHERE
	row_num > 1
ORDER BY
	PropertyAddress



------ Deleting the duplicate rows
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

FROM
	PortfolioProject..NashvilleHousing
--order by ParcelID
						)
DELETE
FROM
	RowNumCTE
WHERE
	row_num > 1
-- ORDER BY PropertyAddress






---------------------------------------------------------------------------------------------------------

--6. Deleting Unused Columns



SELECT *
FROM
	PortfolioProject..NashvilleHousing


ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate















