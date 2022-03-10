using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.ContactActivities
{
    [Table("ATTACHMENTCONTENT")]
    public class AttachmentContent
    {
        [Obsolete("For Persistent Purposes")]
        public AttachmentContent()
        {
        }

        public AttachmentContent(byte[] content, string fileName, string contentType)
        {
            if(content == null) throw new ArgumentNullException("content");
            if(fileName == null) throw new ArgumentNullException("fileName");

            Content = content;
            FileName = fileName;
            ContentType = contentType;
        }

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Column("ID")]
        public int Id { get; protected set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays")]
        [Required]
        public byte[] Content { get; protected set; }

        [Required]
        public string FileName { get; protected set; }

        [Required]
        public string ContentType { get; protected set; }
    }
}