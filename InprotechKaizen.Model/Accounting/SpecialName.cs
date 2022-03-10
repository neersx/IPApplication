using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Accounting
{
    [Table("SPECIALNAME")]
    public class SpecialName
    {
        [Obsolete("For Persistence Only...")]
        public SpecialName()
        {
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        public SpecialName(bool? entityFlag, Name entityName)
        {
            if (entityName == null) throw new ArgumentNullException("entityName");

            IsEntity = Convert.ToDecimal(entityFlag);
            SetEntityName(entityName);
        }

        [Key]
        [Column("NAMENO")]
        [ForeignKey("EntityName")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int Id { get; set; }

        [Column("ENTITYFLAG")]
        public decimal? IsEntity { get; set; }

        [Column("IPOFFICEFLAG")]
        public decimal? IsIpOffice { get; set; }

        [Column("BANKFLAG")]
        public decimal? IsBankOrFinancialInstitution { get; set; }

        [Column("LASTOPENITEMNO")]
        public int? LastOpenItemNo { get; set; }

        [Column("LASTDRAFTNO")]
        public int? LastDraftNo { get; set; }

        [Column("LASTARNO")]
        public int? LastAccountsReceivableNo { get; set; }

        [Column("LASTINTERNALITEMNO")]
        public int? LastInternalItemNo { get; set; }

        [MaxLength(3)]
        [Column("CURRENCY")]
        public string Currency { get; set; }

        [Column("LASTAPNO")]
        public int? LastAccountsPayableNo { get; set; }

        public virtual Name EntityName { get; protected set; }

        public void SetEntityName(Name entityName)
        {
            if (entityName == null) throw new ArgumentNullException(nameof(entityName));

            EntityName = entityName;
            Id = entityName.Id;
        }
    }
}