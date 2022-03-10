namespace Inprotech.Infrastructure.SearchResults.Exporters
{
    public class Column
    {
        public Column(string name, string title, string format)
        {
            Name = name;
            Title = title;
            Format = format;
        }

        public Column()
        {

        }

        public string Name { get; set; }
        public string Title { get; set; }
        public string Format { get; set; }
        public string CurrencyCodeColumnName { get; set; }
        public int? DecimalPlaces { get; set; }
        public string ColumnItemId { get; set; }
    }
}
