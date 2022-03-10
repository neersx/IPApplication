using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("IMAGEDETAIL")]
    public class ImageDetail
    {
        [Obsolete("For persistence only.")]
        public ImageDetail() { }

        public ImageDetail(int imageId)
        {
            ImageId = imageId;
        }

        [Column("IMAGEID")]
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int ImageId { get; internal set; }

        [Column("IMAGESTATUS")]
        public int? ImageStatus { get; set; }

        [MaxLength(254)]
        [Column("IMAGEDESC")]
        public string ImageDescription { get; set; }

        [MaxLength(100)]
        [Column("CONTENTTYPE")]
        public string ContentType { get; set; }

        [Column("IMAGEDESC_TID")]
        public int? DescriptionTId { get; set; }
    }
}
