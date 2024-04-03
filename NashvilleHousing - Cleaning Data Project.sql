/*

Cleaning Data in SQL Queries

*/

SELECT *
FROM PortfolioProject..NashvilleHousing

---------------------------------------------------------------------------------------------------

-- Standardize Date Format

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM PortfolioProject..NashvilleHousing

/*
1) First Attempt
*/
--UPDATE NashvilleHousing
--SET SaleDate = CONVERT(Date, SaleDate) -- we want to change datatype of SaleDate from 'Datetime' to just 'Date', but it doesn't work

--ALTER TABLE NashvilleHousing
--ADD SaleDateConverted Date; -- so we add a new column named 'SaleDateConverted' into the 'NashvilleHousing' table with 'Date' datatype

--UPDATE NashvilleHousing
--SET SaleDateConverted = CONVERT(Date, SaleDate) -- then we fill the new column with converted 'SaleDate' data

/*
2) Second Attempt (the worked step)
*/
ALTER TABLE NashvilleHousing
ALTER COLUMN SaleDate DATE -- we directly change the 'SaleDate' datatype from datetime into date

SELECT SaleDate
FROM NashvilleHousing


---------------------------------------------------------------------------------------------------

-- Populate Property Address Data

SELECT *
FROM NashvilleHousing
ORDER BY ParcelID -- we look the ParcelID, and we found it represent the real address (PropertyAddress)

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a -- we see that we have NULL PropertyAddress, and we want to fill it with the data from the same ParcelID
JOIN NashvilleHousing b -- we do Self Join
	ON a.ParcelID = b.ParcelID -- we need to find a way to distinguish the same ParcelID with NULL and not NULL PropertyAddress
	AND a.[UniqueID ] <> b.[UniqueID ] -- so we distinguish it by using 'UniqueID', because it's unique
WHERE a.PropertyAddress IS NULL


UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


---------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress, SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress nvarchar(255)
UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity nvarchar(255)
UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

SELECT *
FROM NashvilleHousing

/*
You can also breakdown the address with PARSENAME function, but make sure the data is separated by '.' as deliminator.
Because our data that contained in 'OwnerAddress' is separated by ',', we must REPLACE it by '.' first.
The PARSENAME order is reverse, so the data index is counted from the last data.
*/
SELECT OwnerAddress,
PARSENAME(REPLACE(OwnerAddress, ',','.') , 3) AS Address,
PARSENAME(REPLACE(OwnerAddress, ',','.') , 2) AS City,
PARSENAME(REPLACE(OwnerAddress, ',','.') , 1) AS State
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress nvarchar(255)
UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.') , 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity nvarchar(255)
UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',','.') , 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState nvarchar(255)
UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',','.') , 1)

SELECT *
FROM NashvilleHousing


---------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in 'SoldAsVacant' field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END


---------------------------------------------------------------------------------------------------

-- Remove Duplicates
/*
To do this, we can assign a number for every row. The number will be put in a new field called 'Row_Num'.
If the data in the row is unique it'll give you '1' as the output, but if the data has duplicate it'll also give you '2'.
To identify that, we will group the data with 'PARTITION BY' of ParcelID, PropertyAddress, SaleDate, SalePrice, 
and LegalReference field. We assume these field are unique between the data.
*/
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference ORDER BY UniqueID) AS Row_Num
FROM NashvilleHousing
ORDER BY ParcelID


/*
We can make a CTE for that queries. Let's call it as 'RowNumCTE'
*/
WITH RowNumCTE AS (
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference ORDER BY UniqueID) AS Row_Num
FROM NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE Row_Num > 1
ORDER BY PropertyAddress


/*
There are 104 rows that Row_Num > 1, it means there ara 104 duplicates. Now we can delete it. BE CAREFUL, this action cannot be undo.
*/
WITH RowNumCTE AS (
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference ORDER BY UniqueID) AS Row_Num
FROM NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE Row_Num > 1


---------------------------------------------------------------------------------------------------

-- Delete Unused Columns
/*
NOTE : DON'T DO DELETE TO YOUR RAW DATA. MAKE SURE YOU HAVE THE BACKUP !!!
*/

SELECT *
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress