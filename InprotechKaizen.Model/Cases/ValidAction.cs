using InprotechKaizen.Model.Cases.Events;
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("VALIDACTION")]
    public class ValidAction
    {
        [Obsolete("For persistence only.")]
        public ValidAction()
        {
        }

        public ValidAction(string countryId, string propertyTypeId, string caseTypeId, string actionId)
        {
            if (actionId == null) throw new ArgumentNullException("actionId");
            if (countryId == null) throw new ArgumentNullException("countryId");
            if (caseTypeId == null) throw new ArgumentNullException("caseTypeId");
            if (propertyTypeId == null) throw new ArgumentNullException("propertyTypeId");

            PropertyTypeId = propertyTypeId;
            CountryId = countryId;
            CaseTypeId = caseTypeId;
            ActionId = actionId;
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public ValidAction(
            string actionName,
            Action action,
            Country country,
            CaseType caseType,
            PropertyType propertyType)
        {
            if(action == null) throw new ArgumentNullException("action");
            if(country == null) throw new ArgumentNullException("country");
            if(caseType == null) throw new ArgumentNullException("caseType");
            if(propertyType == null) throw new ArgumentNullException("propertyType");

            ActionName = actionName;
            Action = action;
            ActionId = action.Code;
            CountryId = country.Id;
            Country = country;
            PropertyType = propertyType;
            PropertyTypeId = propertyType.Code;
            CaseType = caseType;
            CaseTypeId = caseType.Code;
        }

        [Key]
        [MaxLength(2)]
        [Column("ACTION", Order = 0)]
        public string ActionId { get; set; }

        [Key]
        [MaxLength(1)]
        [Column("CASETYPE", Order = 1)]
        public string CaseTypeId { get; set; }

        [Key]
        [MaxLength(1)]
        [Column("PROPERTYTYPE", Order = 2)]
        public string PropertyTypeId { get; set; }
        
        [Key]
        [MaxLength(3)]
        [Column("COUNTRYCODE", Order = 3)]
        public string CountryId { get; set; }

        [MaxLength(50)]
        [Column("ACTIONNAME")]
        public string ActionName { get; set; }

        [Column("ACTIONNAME_TID")]
        public int? ActionNameTId { get; set; }

        [ForeignKey("ActionId")]
        public virtual Action Action { get; protected set; }

        public virtual PropertyType PropertyType { get; protected set; }
        
        public virtual Country Country { get; protected set; }

        [Column("ACTEVENTNO")]
        public int? DateOfLawEventNo { get; set; }

        [Column("RETROEVENTNO")]
        public int? RetrospectiveEventNo { get; set; }

        [Column("DISPLAYSEQUENCE")]
        public short? DisplaySequence { get; set; }

        [ForeignKey("CaseTypeId")]
        public virtual CaseType CaseType { get; protected set; }

        [ForeignKey("DateOfLawEventNo")]
        public virtual Event DateOfLawEvent { get; protected set; }

        [ForeignKey("RetrospectiveEventNo")]
        public virtual Event RetrospectiveEvent { get; protected set; }
    }
}