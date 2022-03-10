namespace InprotechKaizen.Model.Components.Cases.Comparison.Results
{
    public class GoodsServices
    {
        public string TextType { get; set; }

        public short? TextNo { get; set; }

        public Value<LanguagePicklistItem> Language { get; set; }

        public FirstUsedDate FirstUsedDate { get; set; }

        public FirstUsedDate FirstUsedDateInCommerce { get; set; }

        public Value<string> Class { get; set; }

        public Value<string> Text { get; set; }

        public bool MultipleImportedLanguage { get; set; }
    }

    public class LanguagePicklistItem
    {
        public int? Key { get; set; }
        public string Code { get; set; }
        public string Value { get; set; }
    }
}