using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.Components.Cases
{
    public class PropertyTypeListItem
    {
        public int Id { get; set; }

        public string PropertyTypeKey { get; set; }
        
        public string PropertyTypeDescription { get; set; }
        
        public string CountryKey { get; set; }
        
        public int IsDefaultCountry { get; set; }

        public decimal AllowSubClass { get; set; }

        public bool CrmOnly { get; set; }

        public Image Image { get; set; }
    }
}
