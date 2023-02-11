
local SUFFIXES = {"k","M","B","T","qd","Qn","sx","Sp","O","N","de","Ud","DD","tdD","qdD","QnD","sxD","SpD","OcD","NvD","Vgn","UVg","DVg","TVg","qtV","QnV","SeV","SPG","OVG","NVG","TGN","UTG","DTG","tsTG","qtTG","QnTG","ssTG","SpTG","OcTG","NoTG","QdDR","uQDR","dQDR","tQDR","qdQDR","QnQDR","sxQDR","SpQDR","OQDDr","NQDDr","qQGNT","uQGNT","dQGNT","tQGNT","qdQGNT","QnQGNT","sxQGNT","SpQGNT","OQQGNT","NQQGNT","SXGNTL","USXGNTL","DSXGNTL","TSXGNTL","QTSXGNTL","QNSXGNTL","SXSXGNTL","SPSXGNTL","OSXGNTL","NVSXGNTL","SPTGNTL","USPTGNTL","DSPTGNTL","TSPTGNTL","QTSPTGNTL","QNSPTGNTL","SXSPTGNTL","SPSPTGNTL","OSPTGNTL","NVSPTGNTL","OTGNTL","UOTGNTL","DOTGNTL","TOTGNTL","QTOTGNTL","QNOTGNTL","SXOTGNTL","SPOTGNTL","OTOTGNTL","NVOTGNTL","NONGNTL","UNONGNTL","DNONGNTL","SXNONGNTL","SPNONGNTL","OTNONGNTL","NONONGNTL","CENT"}     

-- // Module // --
local Module = {}

function Module:NumberSuffix( Input )
	local Negative = (Input < 0)
	Input = math.abs(Input)
	local Paired = false
	for i, _ in ipairs(SUFFIXES) do
		if Input < math.pow(10, 3 * i) then
			Input = Input / math.pow(10, 3 * (i-1))
			local isComplex = string.find(tostring(Input),".") and string.sub(tostring(Input), 4, 4) ~= "."
			Input = string.sub(tostring(Input), 1, (isComplex and 4) or 3)..(SUFFIXES[i-1] or "")
			Paired = true
			break
		end
	end
	if not Paired then
		local Rounded = math.floor(Input)
		Input = tostring(Rounded)
	end
	return Negative and "-"..Input or Input
end

return Module