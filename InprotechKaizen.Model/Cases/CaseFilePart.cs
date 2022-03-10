using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Cases
{
    [Table("FILEPART")]
    public class CaseFilePart
    {
        [Obsolete("For persistence only.")]
        public CaseFilePart()
        {
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public CaseFilePart(int caseKey)
        {
            CaseId = caseKey;
        }

        [Key]
        [Column("CASEID")]
        public int CaseId { get; protected set; }

        [Column("FILEPART")]
        public short FilePart { get; set; }

        [MaxLength(60)]
        [Column("FILEPARTTITLE")]
        public string FilePartTitle { get; set; }
    }
}
