using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Cases
{
    [Table("CASELOCATION")]
    public class CaseLocation
    {
        [Obsolete("For persistence only.")]
        public CaseLocation()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public CaseLocation(Case @case, TableCode fileLocation, DateTime whenMoved)
        {
            if (fileLocation == null) throw new ArgumentNullException("fileLocation");
            if (@case == null) throw new ArgumentNullException("case");

            CaseId = @case.Id;
            FileLocation = fileLocation;
            FileLocationId = fileLocation.Id;
            WhenMoved = whenMoved;
        }

        [Key]
        [Column("ID")]
        public int Id { get; protected set; }

        [Column("CASEID")]
        public int CaseId { get; protected set; }

        [Column("FILELOCATION")]
        public int FileLocationId { get; set; }

        [Column("FILEPARTID")]
        public short? FilePartId { get; set; }

        [Column("WHENMOVED")]
        public DateTime WhenMoved { get; set; }

        [MaxLength(20)]
        [Column("BAYNO")]
        public string BayNo { get; set; }

        [Column("ISSUEDBY")]
        public int? IssuedBy { get; set; }

        [ForeignKey("FileLocationId")]
        public virtual TableCode FileLocation { get; protected set; }

        public virtual Name Name { get; protected set; }
    }
}