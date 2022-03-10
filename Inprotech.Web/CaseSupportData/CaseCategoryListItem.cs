namespace Inprotech.Web.CaseSupportData
{
    public class CaseCategoryListItem
    {
        public int Id { get; set; }

        public string CaseCategoryKey { get; set; } 
        
        public string CaseCategoryDescription { get; set; }
        
        public string CountryKey { get; set; }  
        
        public int IsDefaultCountry { get; set; }
        
        public string PropertyTypeKey { get; set; }
        
        public string CaseTypeKey { get; set; }

        public string CaseTypeDescription { get; set; }
    }
}
