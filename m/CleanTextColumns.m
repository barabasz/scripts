= let
    Source = XXXXXXXXXXXXXXXXXXXXX,
    CleanTextColumns = Table.TransformColumns(
        Source,
        List.Transform(
            Table.ColumnNames(Source),
            (col) => {col, each if Value.Is(_, type text) then 
                Text.Trim(
                    Text.Replace(
                        Text.Replace(
                            Text.Replace(_, "#(cr)#(lf)", " "), 
                        "#(lf)", " "), 
                    "#(cr)", " ")
                )
            else _, type any}
        )
    )
in
    CleanTextColumns
