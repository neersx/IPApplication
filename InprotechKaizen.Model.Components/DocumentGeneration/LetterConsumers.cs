using System;

namespace InprotechKaizen.Model.Components.DocumentGeneration
{
    [Flags]
    public enum LetterConsumers
    {
        NotSet = 0,
        TimeAndBilling = 1,
        Cases = 32,
        Names = 256,
        InproDoc = 1024,
        DgLib = 2048
    }

    public enum DocumentType
    {
        NotSet = 0,
        Word = 1,
        PDF = 2,
        XML = 3,
        MailMerge = 4
    }
}