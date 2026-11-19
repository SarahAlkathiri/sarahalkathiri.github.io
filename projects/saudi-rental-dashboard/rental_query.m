let
    // path to the folder with the 13 csv files
    Source = Folder.Files("C:\Users\YourName\Downloads\rental_data"),
    CSVs = Table.SelectRows(Source, each Text.Lower([Extension]) = ".csv"),

    // every file has 7 columns in the same order but different header names,
    // so I skip each file's header row and name the columns myself
    Parsed = Table.AddColumn(CSVs, "Data", each Table.Skip(
        Csv.Document([Content], [Delimiter = ",", Columns = 7, Encoding = 65001, QuoteStyle = QuoteStyle.Csv]), 1)),
    Combined = Table.Combine(Parsed[Data]),
    Renamed = Table.RenameColumns(Combined, {
        {"Column1", "Year"}, {"Column2", "Quarter"}, {"Column3", "Region"}, {"Column4", "City"},
        {"Column5", "PropertyType"}, {"Column6", "Contracts"}, {"Column7", "AvgRent"}}),

    // extra spaces in some city names
    Trimmed = Table.TransformColumns(Renamed, {{"Region", Text.Trim, type text}, {"City", Text.Trim, type text}, {"PropertyType", Text.Trim, type text}}),
    Typed = Table.TransformColumnTypes(Trimmed, {{"Year", Int64.Type}, {"Quarter", Int64.Type}, {"Contracts", Int64.Type}, {"AvgRent", type number}}, "en-US"),

    // same region written two ways
    Region1 = Table.ReplaceValue(Typed, "الحدود الشماليه", "الحدود الشمالية", Replacer.ReplaceValue, {"Region"}),
    Region2 = Table.ReplaceValue(Region1, "المنطقة الشرقية", "الشرقية", Replacer.ReplaceValue, {"Region"}),

    // "شقة - سكني" -> Unit = شقة , Use = سكني
    Split = Table.SplitColumn(Region2, "PropertyType", Splitter.SplitTextByDelimiter(" - "), {"Unit", "Use"}),

    // needed for a correct weighted average later
    AddTotal = Table.AddColumn(Split, "TotalRent", each [Contracts] * [AvgRent], type number),
    AddPeriod = Table.AddColumn(AddTotal, "Period", each Text.From([Year]) & "-Q" & Text.From([Quarter]), type text)
in
    AddPeriod
