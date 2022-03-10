using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Cases
{
    [Table("CASEIMAGE")]
    public class CaseImage
    {
        [Obsolete("For persistence only.")]
        public CaseImage()
        {
        }

        public CaseImage(Case @case, int imageId, Int16 sequence, int imageType)
        {
            if (@case == null) throw new ArgumentNullException("case");

            CaseId = @case.Id;
            ImageId = imageId;
            ImageSequence = sequence;
            ImageType = imageType;
        }

        [Column("CASEID")]
        public int CaseId { get; internal set; }

        [Column("IMAGEID")]
        public int ImageId { get; internal set; }

        [Column("IMAGESEQUENCE")]
        public Int16 ImageSequence { get; set; }

        [Column("IMAGETYPE")]
        public int ImageType { get; protected set; }

        [MaxLength(254)]
        [Column("CASEIMAGEDESC")]
        public string CaseImageDescription { get; set; }

        [MaxLength(20)]
        [Column("FIRMELEMENTID")]
        public string FirmElementId { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "Case")]
        public virtual Case Case { get; set; }

        public virtual Image Image { get; set; }
    }
}