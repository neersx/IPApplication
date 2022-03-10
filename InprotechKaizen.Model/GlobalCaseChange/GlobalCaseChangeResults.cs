using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.GlobalCaseChange
{
    [Table("GLOBALCASECHANGERESULTS")]
    public class GlobalCaseChangeResults
    {
        [Key]
        [Column("PROCESSID", Order = 1)]
        public int Id { get; set; }

        [Key]
        [Column("CASEID", Order = 2)]
        public int CaseId { get; set; }

        [Column("OFFICEUPDATED")]
        public bool OfficeUpdated { get; set; }

        [Column("FAMILYUPDATED")]
        public bool FamilyUpdated { get; set; }

        [Column("TITLEUPDATED")]
        public bool TitleUpdated { get; set; }

        [Column("PROFITCENTRECODEUPDATED")]
        public bool ProfitCentreCodeUpdated { get; set; }

        [Column("ENTITYSIZEUPDATED")]
        public bool EntitySizeUpdated { get; set; }

        [Column("PURCHASEORDERNOUPDATED")]
        public bool PurchaseOrderNoUpdated { get; set; }

        [Column("TYPEOFMARKUPDATED")]
        public bool TypeOfMarkUpdated { get; set; }

        [Column("CASETEXTUPDATED")]
        public bool CaseTextUpdated { get; set; }
        [Column("CASENAMEREFERENCEUPDATED")]
        public bool CaseNameReferenceUpdated { get; set; }
        [Column("FILELOCATIONUPDATED")]
        public bool FileLocationUpdated { get; set; }

        [Column("ISPOLICED")]
        public bool IsPoliced { get; set; }

        [Column("STATUSUPDATED")]
        public bool StatusUpdated { get; set; }

        public virtual BackgroundProcess.BackgroundProcess BackgroundProcess { get; set; }

        public virtual Case Case { get; set; }
    }
}