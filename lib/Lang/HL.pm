package Lang::HL;

use strict;
use warnings;
use utf8;
use Regexp::Grammars;

our $VERSION = '5.135';

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

my $groupTable = {};

sub PT::Lang::X {
    my ($class) = @_;

    my $code = 'use strict;
        use warnings;
        use utf8;

        package BaseClass;

        use strict;
        no warnings;
        use utf8;
        use feature qw(signatures);
        no warnings "experimental::signatures";
        no warnings "experimental::smartmatch";
        use Hash::Merge;

        sub new($class) {
            my $hashRef = {};
            return bless $hashRef, $class;
        }

        sub def($class, $variable) {
            return defined($variable);
        }

        sub not($class, $boolOperand) {
            my $not = ! $boolOperand;
            return $not;
        }

        sub arrayElement($class, $array, $element) {
            if( $element ~~ @{$array} ) {
                return 1;
            } else {
                return 0;
            }
        }

        sub arrayDelete($class, $array, $element) {
            delete($array->[$element]);
        }

        sub hashDelete($class, $hash, $element) {
            delete($hash->{$element});
        }

        sub arrayReverse($class, $array) {
            my @reversedArray = reverse(@{$array});
            return \@reversedArray;
        }

        sub arrayJoin($class, $separator, $array) {
            my @array = @{$array};
            return join($separator, $array);
        }

        sub arraySort($class, $array) {
            my @array = @{$array};
            my @sortedArray = sort(@array);
            return \@sortedArray;
        }

        sub arrayUnshift($class, $array, $element) {
            unshift(@{$array}, $element);
        }

        sub arrayShift($class, $array) {
            return shift(@{$array});
        }

        sub arrayPush($class, $array, $element) {
            push(@{$array}, $element);
        }

        sub arrayPop($class, $array) {
            return pop(@{$array});
        }

        sub stringConcat($class, $textOne, $textTwo) {
            return $textOne . $textTwo;
        }

        sub arrayLength($class, $array) {
            my @newArray = @{$array};
            return $#newArray;
        }

        sub arrayMerge($class, $arrayOne, $arrayTwo) {
            my @newArray = ( @{$arrayOne}, @{$arrayTwo} );
            return \@newArray;
        }

        sub hashElement($class, $hash, $element) {
            my %hashMap  = %{$hash};
            if( exists $hashMap{$element} ) {
                return 1;
            } else {
                return 0;
            }
        }

        sub hashKeys($class, $hash) {
            my @keys = keys(%{$hash});
            return \@keys;
        }

        sub hashMerge($class, $hashOne, $hashTwo) {
            my $mergedHash = merge($hashOne, $hashTwo);
            return $mergedHash;
        }

        sub readFile($class, $fileName) {
            my $fileContent;
            open(my $fh, "<:encoding(UTF-8)", $fileName) or die "Cannot open the $fileName file";
            {
                local $/;
                $fileContent = <$fh>;
            }
            close($fh);
            return $fileContent;
        }

        sub writeFile($class, $fileName, $fileContent) {
            open(my $fh, ">:encoding(UTF-8)", $fileName) or die "Cannot open the $fileName file";
            print $fh $fileContent;
            close($fh);
        }

        1;';

    for my $element ( @{$class->{ClassOrStruct}} ) {
        $code .= $element->X();
    }

    #$code .= (       $class->{DefineClass}
    #                 || $class->{DefineStruct} )->X();

    $code .= 'my $object = Main->new(); $object->main();';
    return $code;
}

sub PT::ClassOrStruct::X {
    my ($class) = @_;

    return (      $class->{DefineClass}
               || $class->{DefineStruct} )->X();
}

sub PT::DefineClass::X {
    my ($class) = @_;

    my $code = "";
    for my $element ( @{ $class->{Class}} ) {
        $code .= $element->X();
    }

    return $code;
}

sub PT::DefineStruct::X {
    my ($class) = @_;

    my $code = '
        package Structs;
        use strict;
        use warnings;
        use utf8;
        use feature qw(signatures);
        no warnings "experimental::signatures";
        use Hash::Util;

        sub new($class) {
            my $hashRef = {};
            return bless $hashRef, $class;
        }
    ';

    for my $element ( @{ $class->{Struct}} ) {
        $code .= $element->X();
    }

    $code .= "\n1;\n";
    return $code;
}

sub PT::Struct::X {
    my ($class) = @_;

    my $structName = $class->{StructName}->X();
    my @structElements = $class->{StructElements}->X($structName);

    my $hashName = lcfirst($structName);

    my $structCode = 'sub ' . $hashName . "(\$class) {\n";
    $structCode .= 'my $' . $hashName . ' = {};';

    for my $element (@structElements) {
        if(ref($element) eq "") {
            $structCode .= '$' . $hashName . '->{"' . $element . '"} = "";';
        }

        if(ref($element) eq "ARRAY") {
            my $structHashName = '$class->' . lcfirst($element->[1]) . '()';
            if($element->[1] eq $structName) {
                $structHashName = "\$" . $hashName;
            }

            $structCode .= '$' . $hashName . '->{"' . $element->[0] . '"} = ' . $structHashName . ';';
        }
    }

    $structCode .= "return \$" . $hashName;
    $structCode .= "\n};";
    return $structCode;
}

sub PT::StructElements::X {
    my ($class, $structName) = @_;

    my @structElements;
    for my $element ( @{$class->{StructElement}} ) {
        push @structElements, $element->X($structName);
    }

    return @structElements;
}

sub PT::StructElement::X {
    my ($class, $structName) = @_;

    return (       $class->{StructKey}
                || $class->{StructStructElement} )->X($structName);
}

sub PT::StructKey::X {
    my ($class, $structName) = @_;

    my $structKey = $class->{''};
    return $structKey;
}

sub PT::StructStructElement::X {
    my ($class, $structName) = @_;

    my $structVariable = $class->{StructVariable}->X($structName);
    my $structStructName = $class->{StructName}->X($structName);

    my @structStructElement = ($structVariable, $structStructName);
    return \@structStructElement;
}

sub PT::StructName::X {
    my ($class) = @_;

    my $structStructName = $class->{''};
    return $structStructName;
}

sub PT::MakeStruct::X {
    my ($class, $structName) = @_;

    my $structStructName = $class->{StructName}->X();
    return $structStructName;
}

sub PT::StructAssignment::X {
    my ($class, $structName) = @_;

    my $structVariable = $class->{StructVariable}->X($structName);
    my $structStructName = $class->{MakeStruct}->X($structName);

    my $classVariable = "\$class";
    my $structAssignment = "my \$" . $structVariable . " = ". $classVariable ."->" . lcfirst($structStructName) . '();';
    return $structAssignment;
}

sub PT::StructAccess::X {
    my ($class, $structName) = @_;

    my $structVariable = $class->{StructVariable}->X($structName);
    my @structAccessList = $class->{StructAccessList}->X($structName);

    my $structAccess = "\$\$" . $structVariable;
    for my $element (@structAccessList) {
        if(ref($element) eq "") {
            $structAccess .= '{"' . $element . '"}' ;
        }
        if(ref($element) eq "ARRAY") {
            $structAccess .= '{"' . $element->[0] . '"}' ;
        }
    }

    return $structAccess;
}

sub PT::StructAccessList::X {
    my ($class, $structName) = @_;

    my @structAccessList;
    for my $element ( @{$class->{StructAccessElement}} ) {
        push @structAccessList, $element->X($structName);
    }

    return @structAccessList;
}

sub PT::StructAccessElement::X {
    my ($class, $structName) = @_;

    return (       $class->{StructVariable}
                || $class->{StructKey} )->X($structName);
}

sub PT::StructVariable::X {
    my ($class, $structName) = @_;
    my $structVariable = $class->{''};

    #my @structVariable = split("", $structVariable);
    #shift(@structVariable);
    #$structVariable = join("", @structVariable);
    #$structVariable .= "_";

    return $structVariable;
}

sub PT::Class::X {
    my ($class) = @_;

    my $className = $class->{ClassName}->X();
    my $classBlock = $class->{ClassBlock}->X($className);

    my $classCode = '
        package ' . $className . ';
        use strict;
        use warnings;
        use utf8;
        use feature qw(signatures);
        no warnings "experimental::signatures";
        use Data::Printer;
        use Try::Tiny;
    ';

    $classCode .= $classBlock . "\n1;";
    return $classCode;
}

sub PT::ClassName::X {
    my ($class) = @_;
    my $className = $class->{''};
    return $className;
}

sub PT::ClassBlock::X {
    my ($class, $className) = @_;

    my $classBlock = '
        sub new($class) {
            my $hashRef = { "' . $className . '" => {} };
            return bless $hashRef, $class;
        }
    ';

    my $classLBrace = $class->{ClassLBrace}->X($className);
    my $classGroups = $class->{ClassGroups}->X($className);
    my $classRBrace = $class->{ClassRBrace}->X($className);

    $classBlock .= $classGroups;
    return $classBlock;
}

sub PT::ClassLBrace::X {
    my ($class, $className) = @_;

    return (       $class->{LBrace}
                || $class->{ClassLBraceError}
                || $class->{MissingLBrace} )->X($className);
}

sub PT::MissingLBrace::X {
    my ($class, $className) = @_;

    print "SyntaxError", "\n";
    print "===========", "\n";
    die "Missing { after className '", $className, "'\n";
}

sub PT::ClassLBraceError::X {
    my ($class, $className) = @_;
    my $classLBraceError = $class->{LBraceError}->X($className);

    print "SyntaxError", "\n";
    print "===========", "\n";
    die "Missing { after className '", $className, "', instead found ", $classLBraceError, "\n";
}

sub PT::ClassRBrace::X {
    my ($class, $className) = @_;

    return (       $class->{RBrace}
                || $class->{ClassRBraceError}
                || $class->{MissingRBrace} )->X($className);
}

sub PT::MissingRBrace::X {
    my ($class, $className) = @_;

    print "SyntaxError", "\n";
    print "===========", "\n";
    die "Missing } after class '", $className, "'\n";
}

sub PT::ClassRBraceError::X {
    my ($class, $className) = @_;
    my $classRBraceError = $class->{RBraceError}->X($className);

    print "SyntaxError", "\n";
    print "===========", "\n";
    die "Missing } after class '", $className, "', instead found ", $classRBraceError, "\n";
}

sub PT::ClassGroups::X {
    my ($class, $className) = @_;

    my @classGroups;
    for my $element ( @{$class->{Group}} ) {
        push @classGroups, $element->X($className);
    }

    my $classGroups = join("", @classGroups);
    return $classGroups;
}

sub PT::Group::X {
    my ($class, $className) = @_;

    return (       $class->{Comment}
                || $class->{Parent}
                || $class->{Packages}
                || $class->{ImplementFunction}
                || $class->{EmbedBlock}
                || $class->{Function}
                || $class->{NonSyntaxClass} )->X($className);
}

sub PT::ImplementFunction::X {
    my ($class, $className) = @_;

    my $functionName = $class->{FunctionName}->X($className);
    my $functionParamList = $class->{FunctionParamList}->X($className);

    my $multiLineComment = "";
    if(exists $class->{MultiLineComment}) {
        my $multiLineComment = $class->{MultiLineComment}->X($className);
    }

    my $dieMessage = "function " . $functionName . " in class " . $className . " is not defined \n";
    my $implementFunction = "sub " . $functionName . $functionParamList . "{\n" . $multiLineComment . "\n die(" . $dieMessage . ");}\n";

    return $implementFunction;
}

sub PT::MultiLineComment::X {
    my ($class, $className) = @_;

    my $mlComment = $class->{MLComment}->X($className);
    return $mlComment;
}

sub PT::MLComment::X {
    my ($class, $className) = @_;
    my $mlComment = $class->{''};
    return $mlComment;
}

sub PT::NonSyntaxClass::X {
    my ($class, $className) = @_;
    my $nonSyntax = $class->{''};

    my @nonSyntax = split(" ", $nonSyntax);
    $nonSyntax = $nonSyntax[0];

    print "SyntaxError", "\n";
    print "===========", "\n";
    print "ClassName: ", $className, "\n";
    die "Error: $nonSyntax \n";
}

sub PT::Packages::X {
    my ($class, $className) = @_;

    my @packageList = ($class->{PackageList})->X($className);
    my $packages = join("\n", @packageList);
    return $packages;
}

sub PT::PackageList::X {
    my ($class, $className) = @_;

    my @packageList;
    for my $element ( @{$class->{Package}} ) {
        push @packageList, $element->X($className);
    }

    return @packageList;
}

sub PT::Package::X {
    my ($class, $className) = @_;

    return (       $class->{PackageWithConstructor}
                || $class->{PackageWithoutConstructor} )->X($className);
}

sub PT::PackageWithConstructor::X {
    my ($class, $className) = @_;

    my $object = $class->{Object}->X($className);
    my $packageName = $class->{PackageName}->X($className);
    my $constructor = $class->{Constructor}->X($className);

    if(exists $class->{ObjectParameters}) {
        my $objectParameters = $class->{ObjectParameters}->X($className);
        my $parameters;

        if(ref($objectParameters)) {
            $parameters = join(",", @{$objectParameters});
        } else {
            $parameters = $objectParameters;
        }

        my $packageWithConstructor = "";
        if(exists $class->{Asterisk}) {
            $packageWithConstructor .= "use " . $packageName . ";\n";
        }

        $packageWithConstructor .= "my \$" . $object . " = " . $packageName . "->"
                                   . $constructor . "(" . $parameters . ");\n";

        return $packageWithConstructor;
    }

    my $packageWithConstructor = "";
    if(exists $class->{Asterisk}) {
        $packageWithConstructor .= "use " . $packageName . ";\n";
    }

    $packageWithConstructor .= "my \$" . $object . " = " . $packageName
                               . "->" . $constructor . "();\n";

    return $packageWithConstructor;
}

sub PT::ObjectParameters::X {
    my ($class, $className) = @_;

    return $class->{Parameters}->X($className);
}

sub PT::PackageParams::X {
    my ($class, $className) = @_;
    my @keyValuePairs;

    my $keyValuePairs = "";
    for my $element ( @{ $class->{KeyValue}} ) {
        @keyValuePairs = ();
        push @keyValuePairs, $element->X($className);
        $keyValuePairs .= $keyValuePairs[0] . " => " . $keyValuePairs[1] . ", ";
    }

    return $keyValuePairs;
}

sub PT::PackageName::X {
    my ($class, $className) = @_;

    my @packageDir;
    for my $element ( @{ $class->{PackageDir}} ) {
        push @packageDir, $element->X($className);
    }

    my $packageName = join("::", @packageDir);
    return $packageName;
}

sub PT::PackageWithoutConstructor::X {
    my ($class, $className) = @_;
    my $packageName = $class->{PackageName}->X($className);

    if(exists $class->{QW}) {
        my $qw = $class->{QW}->X($className);

        my $packageWithoutConstructor = "use " . $packageName . $qw . ";\n";
        return $packageWithoutConstructor;
    }

    my $packageWithoutConstructor = "use " . $packageName . ";\n";
    return $packageWithoutConstructor;
}

sub PT::QW::X {
    my ($class, $className) = @_;

    my @functionList = $class->{FunctionList}->X($className);
    my $qw = " qw(";
    my $funcitonList = join(" ", @functionList);
    $qw .= $funcitonList . ")";
}

sub PT::FunctionList::X {
    my ($class, $className) = @_;

    my @functionList;
    for my $element ( @{ $class->{FunctionName}} ) {
        push @functionList, $element->X($className);
    }

    return @functionList;
}

sub PT::Constructor::X {
    my ($class, $className) = @_;

    my $constructor = $class->{''};
    return $constructor;
}

sub PT::Object::X {
    my ($class, $className) = @_;

    my $object = $class->{''};
    return $object;
}

sub PT::PackageDir::X {
    my ($class, $className) = @_;

    my $packageDir = $class->{''};
    return $packageDir;
}

sub PT::Parent::X {
    my ($class, $className) = @_;
    my $parent = 'our @ISA = qw(';

    my $classNames = $class->{ClassNames}->X($className);
    $parent .= $classNames . ");\n";
}

sub PT::ClassNames::X {
    my ($class, $className) = @_;

    my @classNames;
    for my $element ( @{$class->{ClassName}} ) {
        push @classNames, $element->X($className);
    }

    my $classNames = join(" ", @classNames);
    return $classNames;
}

sub PT::Comment::X {
    my ($class, $className) = @_;
    my $comment = $class->{LineComment}->X($className);
    $comment = "\n" . "# " . $comment . "\n";
    return $comment;
}

sub PT::LineComment::X {
    my ($class, $className) = @_;
    return $class->{''};
}

sub PT::Function::X {
    my ($class, $className) = @_;

    my $functionName = $class->{FunctionName}->X($className);
    my $functionParamList = $class->{FunctionParamList}->X($className);
    my $codeBlock = $class->{CodeBlock}->X($className, $functionName);

    my $function = "\n sub " . $functionName . $functionParamList . $codeBlock;
    return $function;
}

sub PT::FunctionName::X {
    my ($class, $className) = @_;

    my $functionName = $class->{''};
    return $functionName;
}

sub PT::FunctionParamList::X {
    my ($class, $className) = @_;

    my @params = (       $class->{EmptyParamList}
                      || $class->{FunctionParams} )->X($className);

    my $functionParamList;
    $functionParamList = '( $class, ';

    if($#params >= 0) {
        foreach my $param (@params) {
            if( $param eq "" ) {} else {
                $functionParamList .= "\$" . $param . ",";
            }
        }
        if( substr($functionParamList, -1) eq "," ) {
            chop($functionParamList);
        }
    }
    else {
        chop($functionParamList);
    }
    $functionParamList .= ")";

    return $functionParamList;
}

sub PT::CodeBlock::X {
    my ($class, $className, $functionName) = @_;
    my $blocks = $class->{Blocks}->X($className, $functionName);
    my $codeBlock = "{\n" . $blocks . "\n}";
    return $codeBlock;
}

sub PT::EmptyParamList::X {
    my ($class, $className) = @_;
    return $class->{''};
}

sub PT::FunctionParams::X {
    my ($class, $className) = @_;
    my @functionParams;

    for my $element ( @{ $class->{Arg}} ) {
        push @functionParams, $element->X($className);
    }

    return @functionParams;
}

sub PT::Arg::X {
    my ($class, $className) = @_;
    return $class->{''};
}

sub PT::Blocks::X {
    my ($class, $className, $functionName) = @_;
    my @blocks;

    for my $element ( @{$class->{Block}} ) {
        push @blocks, $element->X($className, $functionName);
    }

    my $blocks = join("\n", @blocks);
    return $blocks;
}

sub PT::Block::X {
    my ($class, $className, $functionName) = @_;

    my $block = (      $class->{IfElse}
                    || $class->{While}
                    || $class->{ForEach}
                    || $class->{ArrayEach}
                    || $class->{HashEach}
                    || $class->{For}
                    || $class->{RegexMatch}
                    || $class->{TryCatch}
                    || $class->{EmbedBlock}
                    || $class->{Comment}
                    || $class->{Statement}
                    || $class->{Packages}
                    || $class->{NonSyntaxFunction} )->X($className, $functionName);
    return $block;
}

sub PT::RegexMatch::X {
    my ($class, $className) = @_;

    my $pattern = $class->{Pattern}->X($className);
    my $matchString = $class->{MatchString}->X($className);
    my $codeBlock = $class->{CodeBlock}->X($className);

    my $regexMatch = "if(" . $matchString . " =~ " . $pattern . ")" . $codeBlock;
    return $regexMatch;
}

sub PT::Pattern::X {
    my ($class, $className) = @_;

    my $pattern = $class->{VariableName}->X($className);
    return $pattern;
}

sub PT::MatchString::X {
    my ($class, $className) = @_;

    my $matchString = $class->{VariableName}->X($className);
    return $matchString;
}

sub PT::TryCatch::X {
    my ($class, $className) = @_;

    my $codeBlock = $class->{CodeBlock}->X($className);
    if(exists $class->{CatchBlock}) {
        my $catchBlock = $class->{CatchBlock}->X($className);
        my $tryCatch = "try " . $codeBlock . $catchBlock . ";";
        return $tryCatch;
    } else {
        my $tryCatch = "try {\n " . $codeBlock . "\n}";
        return $tryCatch;
    }
}

sub PT::CatchBlock::X {
    my ($class, $className) = @_;

    my $codeBlock = $class->{CodeBlock}->X($className);
    my @codeBlock = split(" ", $codeBlock);
    shift(@codeBlock);
    my $catchBlock = " catch {\n my \$error = \$_;\n " . join(" ", @codeBlock);

    return $catchBlock;
}

sub PT::NonSyntaxFunction::X {
    my ($class, $className, $functionName) = @_;
    my $nonSyntax = $class->{''};

    my @nonSyntax = split(" ", $nonSyntax);
    $nonSyntax = $nonSyntax[0];

    print "SyntaxError", "\n";
    print "===========", "\n";
    print "ClassName: ", $className, "\n";

    if(defined $functionName) {
    	print "FunctionName: ", $functionName, "\n";
    }

    die "Error: $nonSyntax \n";
}

sub PT::EmbedBlock::X {
    my ($class, $className) = @_;

    my $embedBlock = $class->{EmbedCodeBlock}->X($className);
    return $embedBlock;
}

sub PT::EmbedCodeBlock::X {
    my ($class, $className) = @_;

    my $embedCode = $class->{EmbeddedCode}->X($className);
    return $embedCode;
}

sub PT::EmbeddedCode::X {
    my ($class, $className) = @_;

    my $embedCode = $class->{''};
    return $embedCode;
}

sub PT::While::X {
    my ($class, $className) = @_;

    my $boolExpression = $class->{BoolExpression}->X($className);
    my $codeBlock = $class->{CodeBlock}->X($className);

    my $while = "\n while ( " . $boolExpression . " ) " . $codeBlock;
    return $while;
}

sub PT::ForEach::X {
    my ($class, $className) = @_;

    my $forEachVariableName = $class->{VariableName}->X($className);
    my @forRange = $class->{ForRange}->X($className);
    my $codeBlock = $class->{CodeBlock}->X($className);

    my $forEach = "\n foreach my " . $forEachVariableName . " ( " . $forRange[0]
                  . " ... " . $forRange[1] . " ) " . $codeBlock;

    return $forEach;
}

sub PT::ForEachVariableName::X {
    my ($class, $className) = @_;

    my $variableName = $class->{VariableName}->X($className);
    return $variableName;
}

sub PT::ArrayEach::X {
    my ($class, $className) = @_;

    my $variableName = $class->{VariableName}->X($className);
    my $arrayEachVariableName = $class->{ArrayEachVariableName}->X($className);
    my $arrayEachNumber = $class->{ArrayEachNumber}->X($className);
    my $codeBlock = $class->{CodeBlock}->X($className);

    my @codeBlock = split(" ", $codeBlock);
    shift(@codeBlock);
    $codeBlock = join(" ", @codeBlock);

    my $arrayEachCodeBlock = "my " . $arrayEachVariableName . " = " . $variableName . "->[" . $arrayEachNumber . "];\n" . $codeBlock;
    my $arrayEach = "\n for my " . $arrayEachNumber . "( 0 ... " . "\$class->arrayLength(" . $variableName . ") ) {\n" . $arrayEachCodeBlock;

    return $arrayEach;
}

sub PT::ArrayEachVariableName::X {
    my ($class, $className) = @_;

    my $variableName = $class->{VariableName}->X($className);
    return $variableName;
}

sub PT::ArrayEachNumber::X {
    my ($class, $className) = @_;

    my $variableName = $class->{VariableName}->X($className);
    return $variableName;
}

sub PT::HashEach::X {
    my ($class, $className) = @_;

    my $variableName = $class->{VariableName}->X($className);
    my $hashEachKey = $class->{HashEachKey}->X($className);
    my $hashEachValue = $class->{HashEachValue}->X($className);
    my $codeBlock = $class->{CodeBlock}->X($className);

    my $hashEach = "\n keys %{" . $variableName . "};\n while(my (" . $hashEachKey
                   . ", " . $hashEachValue . ") = each %{ " . $variableName . " }) " . $codeBlock;

    return $hashEach;
}

sub PT::HashEachKey::X {
    my ($class, $className) = @_;

    my $hashEachKey = $class->{VariableName}->X($className);
    return $hashEachKey;
}

sub PT::HashEachValue::X {
    my ($class, $className) = @_;

    my $hashEachValue = $class->{VariableName}->X($className);
    return $hashEachValue;
}

sub PT::For::X {
    my ($class, $className) = @_;

    my $variableName = $class->{VariableName}->X($className);
    my @forRange = $class->{ForRange}->X($className);
    my $codeBlock = $class->{CodeBlock}->X($className);

    my $for = "\n for my " . $variableName . " ( " . $forRange[0]
              . " ... " . $forRange[1] . " ) " . $codeBlock;

    return $for;
}

sub PT::ForRange::X {
    my ($class, $className) = @_;

    my $lowerRange = $class->{LowerRange}->X($className);
    my $upperRange = $class->{UpperRange}->X($className);

    my @forRange = ($lowerRange, $upperRange);
    return @forRange;
}

sub PT::LowerRange::X {
    my ($class, $className) = @_;

    my $number = (     $class->{Number}
                    || $class->{String}
                    || $class->{VariableName}
                    || $class->{ArrayElement}
                    || $class->{StructAccess}
                    || $class->{HashElement}
                    || $class->{ClassAccessor}
                    || $class->{ClassFunctionReturn}
                    || $class->{FunctionReturn} )->X($className);

    return $number;
}

sub PT::UpperRange::X {
    my ($class, $className) = @_;

    my $number = (     $class->{Number}
                    || $class->{String}
                    || $class->{VariableName}
                    || $class->{ArrayElement}
                    || $class->{StructAccess}
                    || $class->{HashElement}
                    || $class->{ClassAccessor}
                    || $class->{ClassFunctionReturn}
                    || $class->{FunctionReturn} )->X($className);

    return $number;
}

sub PT::IfElse::X {
    my ($class, $className) = @_;
    my $if = $class->{If}->X($className);

    my $elsif;
    my $else;

    if( exists $class->{ElsIf} ) {
        $elsif = $class->{ElsIf}->X($className);
    }
    if( exists $class->{Else} ) {
        $else = $class->{Else}->X($className);
    }

    my $ifElseIf;
    if (defined $elsif) {
        $ifElseIf = $if . $elsif . $else;
        return $ifElseIf;
    }
    if (defined $else) {
        $ifElseIf = $if . $else;
        return $ifElseIf;
    }

    $ifElseIf = $if;
    return $ifElseIf;
}

sub PT::IfElseIf::X {
    my ($class, $className) = @_;
    my $if = $class->{If}->X($className);

    my $elsif;
    my $else;

    if( exists $class->{ElsIf} ) {
        $elsif = $class->{ElsIf}->X($className);
    }
    if( exists $class->{Else} ) {
        $else = $class->{Else}->X($className);
    }

    my $ifElseIf;
    if (defined $elsif) {
        $ifElseIf = $if . $elsif . $else;
        return $ifElseIf;
    }
    if (defined $else) {
        $ifElseIf = $if . $else;
        return $ifElseIf;
    }

    $ifElseIf = $if;
    return $ifElseIf;
}

sub PT::If::X {
    my ($class, $className) = @_;

    my $boolExpression = $class->{BoolExpression}->X($className);
    my $codeBlock = $class->{CodeBlock}->X($className);

    my $if = "\n if ( " . $boolExpression . " ) " . $codeBlock;
    return $if;
}

sub PT::BoolExpression::X {
    my ($class, $className) = @_;
    my @booleanExpressions;

    for my $element ( @{ $class->{BooleanExpression}} ) {
        push @booleanExpressions, $element->X($className);
    }

    my @boolOperators;

    for my $element (@{ $class->{BoolOperator} }) {
        push @boolOperators, $element->X($className);
    }

    my $boolExpression = $booleanExpressions[0];
    for my $counter (1 .. $#booleanExpressions) {
        $boolExpression .= $boolOperators[$counter - 1] . " " . $booleanExpressions[$counter];
    }

    return $boolExpression;
}

sub PT::BooleanExpression::X {
    my ($class, $className) = @_;
    my $boolExpression;

    my $boolOperand = $class->{BoolOperands}->X($className);
    if( exists $class->{BoolOperatorExpression} ) {
        my @boolOperatorExpression = $class->{BoolOperatorExpression}->X($className);
        $boolExpression = $boolOperand . " "
                          . $boolOperatorExpression[0] . " " . $boolOperatorExpression[1];
        return $boolExpression;
    }

    $boolExpression = $boolOperand;
    return $boolExpression;
}

sub PT::BoolOperatorExpression::X {
    my ($class, $className) = @_;

    my $boolOperator = $class->{BoolOperator}->X($className);
    my $boolOperand = $class->{BoolOperands}->X($className);

    my @boolOperatorExpression = ($boolOperator, $boolOperand);
    return @boolOperatorExpression;
}

sub PT::BoolOperator::X {
    my ($class, $className) = @_;
    return (       $class->{GreaterThan}
                || $class->{LessThan}
                || $class->{Equals}
                || $class->{GreaterThanEquals}
                || $class->{LessThanEquals}
                || $class->{StringEquals}
                || $class->{StringNotEquals}
                || $class->{NotEqulas}
                || $class->{LogicalAnd}
                || $class->{LogicalOr}
                || $class->{Percent}
                || $class->{EmbedBlock} )->X($className);
}

sub PT::BoolOperands::X {
    my ($class, $className) = @_;
    return (       $class->{RealNumber}
                || $class->{String}
                || $class->{ScalarVariable}
                || $class->{ArrayElement}
                || $class->{StructAccess}
                || $class->{HashElement}
                || $class->{ClassAccessor}
                || $class->{ClassFunctionReturn}
                || $class->{FunctionReturn}
                || $class->{EmbedBlock} )->X($className);
}

sub PT::ElsIf::X {
    my ($class, $className) = @_;
    my @elsIfChain;

    for my $element ( @{$class->{ElsIfChain}} ) {
        push @elsIfChain, $element->X($className);
    }

    my $elsIfChain;
    foreach my $elsIf (@elsIfChain) {
        $elsIfChain .= $elsIf;
    }

    return $elsIfChain;
}

sub PT::ElsIfChain::X {
    my ($class, $className) = @_;
    my $boolExpression = $class->{BoolExpression}->X($className);
    my $codeBlock = $class->{CodeBlock}->X($className);

    my $elsIf = "\n elsif ( " . $boolExpression . " ) " . $codeBlock;
    return $elsIf;
}

sub PT::Else::X {
    my ($class, $className) = @_;
    my $codeBlock = $class->{CodeBlock}->X($className);

    my $else = "\n else " . $codeBlock;
    return $else;
}

sub PT::Statement::X {
    my ($class, $className) = @_;
    return (       $class->{VariableDeclaration}
                || $class->{FunctionCall}
                || $class->{Assignment}
                || $class->{StructAssignment}
                || $class->{PackageNameStatement}
                || $class->{PackageFunctionStatement}
                || $class->{Regex}
                || $class->{ClassFunctionCall}
                || $class->{FunctionReferenceCallStatement}
                || $class->{Return}
                || $class->{Last}
                || $class->{Next}
                || $class->{ObjectCall} )->X($className);
}

sub PT::PackageNameStatement::X {
    my ($class, $className) = @_;

    my $packageName = $class->{PackageName}->X($className);
    my $packageNameStatement = $packageName . ";\n";
    return $packageNameStatement;
}

sub PT::PackageFunctionStatement::X {
    my ($class, $className) = @_;

    my $packageFunction = $class->{PackageFunction}->X($className);
    my $packageFunctionStatement = $packageFunction . ";\n";
    return $packageFunctionStatement;
}

sub PT::PackageFunction::X {
    my ($class, $className) = @_;

    my $packageName = $class->{PackageName}->X($className);
    my $packageFunction = $packageName . "\(" . "\)";

    if(exists $class->{Parameters}) {
        my @parameters = @{$class->{Parameters}->X($className)};
        my $params = join(",", @parameters);
        $packageFunction = $packageName . "\(" . $params . "\)";
    }

    return $packageFunction;
}

sub PT::FunctionReferenceCall::X {
    my ($class, $className) = @_;

    my $functionName = $class->{FunctionName}->X($className);

    my $parametersList = "\$class";
    if(exists $class->{Parameters}) {
        my @parameters = @{$class->{Parameters}->X($className)};
        $parametersList = join(",", @parameters);
    }

    my $functionReferenceCall = "\&\$" . $functionName . "(\$class, " . $parametersList . ")";
    return $functionReferenceCall;
}

sub PT::FunctionReferenceCallStatement::X {
    my ($class, $className) = @_;

    my $functionReferenceCall = $class->{FunctionReferenceCall}->X($className);
    my $functionReferenceCallStatement = $functionReferenceCall . ";\n";
    return $functionReferenceCallStatement;
}

sub PT::Regex::X {
    my ($class, $className) = @_;

    my $regexVariable = $class->{RegexVariable}->X($className);
    my $regexp = $class->{Regexp}->X($className);
    my $modifiers = $class->{Modifiers}->X($className);

    my $regex = "my ". $regexVariable . " = qr{\n " . $regexp . "\n}" . $modifiers . ";";
    return $regex;
}

sub PT::RegexVariable::X {
    my ($class, $className) = @_;

    my $regexVariable = $class->{VariableName}->X($className);
    return $regexVariable;
}

sub PT::Regexp::X {
    my ($class, $className) = @_;

    my $regex = $class->{Pre}->X($className);
    return $regex;
}

sub PT::Pre::X {
    my ($class, $className) = @_;

    my $regex = $class->{''};
    return $regex;
}

sub PT::Modifiers::X {
    my ($class, $className) = @_;

    my $regexModifiers = $class->{RegexModifiers}->X($className);
    return $regexModifiers;
}

sub PT::RegexModifiers::X {
    my ($class, $className) = @_;

    my $regexModifiers = $class->{''};
    return $regexModifiers;
}

sub PT::ObjectCall::X {
        my ($class, $className) = @_;
        my $objectCall = "";

        $objectCall .= $class->{ObjectFunctionCall}->X($className);
        $objectCall .= ";\n";

        return $objectCall;
}

sub PT::VariableDeclaration::X {
    my ($class, $className) = @_;
    return (       $class->{ScalarDeclaration}
                || $class->{ArrayDeclaration}
                || $class->{HashDeclaration} )->X($className);
}

sub PT::ScalarDeclaration::X {
    my ($class, $className) = @_;
    my $variableName = $class->{VariableName}->X($className);
    my $value = $class->{Value}->X($className);

    my $scalarDeclaration = "\n my " . $variableName
                            .  " = " . $value . ";\n";
    return $scalarDeclaration;
}

sub PT::VariableName::X {
    my ($class, $className) = @_;
    my $variableName = $class->{''};
    return "\$" . $variableName;
}

sub PT::Value::X {
    my ($class, $className) = @_;
    my $rhs = $class->{RHS}->X($className);
    return $rhs;
}

sub PT::Number::X {
    my ($class, $className) = @_;
    my $number = $class->{''};
    return $number;
}

sub PT::RealNumber::X {
    my ($class, $className) = @_;
    my $realNumber = $class->{''};
    return $realNumber;
}

sub PT::String::X {
    my ($class, $className) = @_;
    my $stringValue = $class->{StringValue}->X($className);

    my $string = "\"" . $stringValue . "\"";
}

sub PT::StringValue::X {
    my ($class, $className) = @_;
    my $stringValue = $class->{''};
    return $stringValue;
}

sub PT::ArrayDeclaration::X {
    my ($class, $className) = @_;
    my $variableName = $class->{VariableName}->X($className);
    my $arrayList = $class->{ArrayList}->X($className);

    my $arrayDeclaration = "\n my " . $variableName
                           . " = " . $arrayList . ";\n";

    return $arrayDeclaration;
}

sub PT::ArrayList::X {
    my ($class, $className) = @_;
    my $arrayList = "[";
    my @listElements = $class->{ListElements}->X($className);

    $arrayList .= join(",", @listElements);

    $arrayList .= "]";
    return $arrayList;
}

sub PT::ListElements::X {
    my ($class, $className) = @_;
    my @listElements;

    for my $element ( @{ $class->{ListElement}} ) {
        push @listElements, $element->X($className);
    }

    return @listElements;
}

sub PT::ListElement::X {
    my ($class, $className) = @_;
    return (       $class->{RealNumber}
                || $class->{String}
                || $class->{ArrayList}
                || $class->{StructAccess}
                || $class->{HashRef}
                || $class->{ClassFunctionReturn}
                || $class->{FunctionReturn}
                || $class->{ArrayElement}
                || $class->{HashElement}
                || $class->{VariableName}
                || $class->{ClassAccessor}
                || $class->{ObjectFunctionCall}
                || $class->{EmbedBlock} )->X($className);
}

sub PT::HashDeclaration::X {
    my ($class, $className) = @_;
    my $variableName = $class->{VariableName}->X($className);
    my $hashRef = $class->{HashRef}->X($className);

    my $hashDeclaration = "\n my " . $variableName
                          . " = " . $hashRef . ";\n";
}

sub PT::HashRef::X {
    my ($class, $className) = @_;
    my $hashRef = "{";
    my $keyValuePairs = $class->{KeyValuePairs}->X($className);
    $hashRef .= $keyValuePairs . "}";
    return $hashRef;
}

sub PT::KeyValuePairs::X {
    my ($class, $className) = @_;
    my @keyValuePairs;

    my $keyValuePairs = "";
    for my $element ( @{ $class->{KeyValue}} ) {
        @keyValuePairs = ();
        push @keyValuePairs, $element->X($className);
        $keyValuePairs .= $keyValuePairs[0] . " => " . $keyValuePairs[1] . ", ";
    }

    return $keyValuePairs;
}

sub PT::KeyValue::X {
    my ($class, $className) = @_;
    my $pairKey = $class->{PairKey}->X($className);
    my $pairValue = $class->{PairValue}->X($className);

    my @keyValue = ($pairKey, $pairValue);
    return @keyValue;
}

sub PT::PairKey::X {
    my ($class, $className) = @_;
    return (       $class->{Number}
                || $class->{String}
                || $class->{StructAccess}
                || $class->{ClassFunctionReturn}
                || $class->{FunctionReturn}
                || $class->{VariableName}
                || $class->{EmbedBlock} )->X($className);
}

sub PT::PairValue::X {
    my ($class, $className) = @_;
    return (       $class->{RealNumber}
                || $class->{String}
                || $class->{ArrayList}
                || $class->{HashRef}
                || $class->{VariableName}
                || $class->{ArrayElement}
                || $class->{StructAccess}
                || $class->{HashElement}
                || $class->{PackageFunction}
                || $class->{ClassFunctionReturn}
                || $class->{FunctionReturn}
                || $class->{FunctionReference}
                || $class->{ClassAccessor}
                || $class->{ObjectFunctionCall}
                || $class->{EmbedBlock} )->X($className);
}

sub PT::FunctionCall::X {
    my ($class, $className) = @_;
    my $functionName = $class->{FunctionName}->X($className);

    my $functionCall = $functionName . "(" ;

    if(exists $class->{Parameters}) {
        my @parameters = @{$class->{Parameters}->X($className)};
        $functionCall .= join(",", @parameters);
    }

    $functionCall .= ");";
    return $functionCall;
}

sub PT::Parameters::X {
    my ($class, $className) = @_;
    my @parameters;

    for my $element (@{ $class->{Param} }) {
        push @parameters, $element->X($className);
    }

    return \@parameters;
}

sub PT::Param::X {
    my ($class, $className) = @_;
    return (       $class->{RealNumber}
                || $class->{String}
                || $class->{VariableName}
                || $class->{ArrayElement}
                || $class->{ClassAccessor}
                || $class->{StructAccess}
                || $class->{HashElement}
                || $class->{PerlObject}
                || $class->{ParamsNotHash}
                || $class->{HashRef}
                || $class->{FunctionReturn}
                || $class->{ClassFunctionReturn}
                || $class->{EmbedBlock}
                || $class->{FunctionReference}
                || $class->{ClassFunctionReturn}
                || $class->{Calc}
                || $class->{ParamChars}
                || $class->{ObjectFunctionCall} )->X($className);
}

sub PT::ParamsNotHash::X {
    my ($class, $className) = @_;

    my $packageParams = $class->{PackageParams}->X($className);
    return $packageParams;
}

sub PT::PerlObject::X {
    my ($class, $className) = @_;

    my $perlObjectName = $class->{PerlObjectName}->{$className};
    my $perlObject = "\$" . $perlObjectName;
    return $perlObject;
}

sub PT::ParamChars::X {
    my ($class, $className) = @_;
    my $paramChars = $class->{ParamCharacters}->X($className);
    return $paramChars;
}

sub PT::ParamCharacters::X {
    my ($class, $className) = @_;
    my $paramCharacters = $class->{''};
    return $paramCharacters;
}

sub PT::Assignment::X {
    my ($class, $className) = @_;

    return (       $class->{StructAssignment}
                || $class->{ScalarAssignment}
                || $class->{StructAssignmentStatement}
                || $class->{ArrayAssignment}
                || $class->{HashAssignment}
                || $class->{AccessorAssignment} )->X($className);
}

sub PT::StructAssignmentStatement::X {
    my ($class, $className) = @_;

    my $structAccess = $class->{StructAccess}->X($className);
    my $rhs = $class->{RHS}->X($className);

    my $structAssignment = $structAccess . " = " . $rhs . ";\n";
    return $structAssignment;
}

sub PT::AccessorAssignment::X {
    my ($class, $className) = @_;

    my $variableName = $class->{HashKeyStringValue}->X($className);
    my $rhs = $class->{RHS}->X($className);

    my $accessorAssignment  = '$class->{"' . $className . '"}->{"'. $variableName .'"} = ' . $rhs .';';
    return $accessorAssignment;
}

sub PT::ScalarAssignment::X {
    my ($class, $className) = @_;
    my $lhs = $class->{ScalarVariable}->X($className);
    my $rhs = $class->{RHS}->X($className);

    my $scalarAssignment = $lhs . " = " . $rhs . ";\n";
    return $scalarAssignment;
}

sub PT::LHS::X {
    my ($class, $className) = @_;
    my $scalarVariable = $class->{ScalarVariable}->X($className);

    return $scalarVariable;
}

sub PT::ScalarVariable::X {
    my ($class, $className) = @_;

    my $scalarVariable = "\$";
    $scalarVariable .= $class->{''};

    return $scalarVariable;
}

sub PT::RHS::X {
    my ($class, $className) = @_;

    return (       $class->{RealNumber}
                || $class->{FunctionReturn}
                || $class->{ArrayElement}
                || $class->{HashElement}
                || $class->{ScalarVariable}
                || $class->{Calc}
                || $class->{PackageName}
                || $class->{StructAccess}
                || $class->{PackageFunction}
                || $class->{RegexMatchVariables}
                || $class->{ArrayList}
                || $class->{HashRef}
                || $class->{FunctionReference}
                || $class->{FunctionReferenceCall}
                || $class->{ClassAccessor}
                || $class->{ClassFunctionReturn}
                || $class->{String}
                || $class->{ParamChars}
                || $class->{STDIN}
                || $class->{ObjectFunctionCall}
                || $class->{EmbedBlock} )->X($className);
}

sub PT::RegexMatchVariables::X {
    my ($class, $className) = @_;

    my $matchVariable = $class->{MatchVariable}->X($className);
    my $regexMatchVariables = "";

    if( $matchVariable =~ /\d+/ ) {
        $regexMatchVariables = "\$" . $matchVariable;
    }

    if( $matchVariable eq "Match" ) {
        $regexMatchVariables = "\$" . "\&";
    }

    if( $matchVariable eq "PREMATCH" ) {
        $regexMatchVariables = "\$" . "\'";
    }

    if( $matchVariable eq "POSTMATCH" ) {
        $regexMatchVariables = "\$" . "\`";
    }

    return $regexMatchVariables;
}

sub PT::MatchVariable::X {
    my ($class, $className) = @_;

    return (        $class->{Number}
                 || $class->{MatchParts} )->X($className);
}

sub PT::MatchParts::X {
    my ($class, $className) = @_;
    return $class->{''};
}

sub PT::FunctionReference::X {
    my ($class, $className) = @_;

    my $functionName = $class->{FunctionName}->X($className);

    my $parametersList;
    if(exists $class->{Parameters}) {
        my @parameters = @{$class->{Parameters}->X($className)};
        $parametersList = join(",", @parameters);
    }

    my $functionReference = "";
    if(defined $parametersList) {
        $functionReference = "\\&" . $functionName . "," . $parametersList;
    } else {
        $functionReference = "\\&" . $functionName;
    }

    return $functionReference;
}

sub PT::STDIN::X {
    my ($class, $className) = @_;
    my $stdin = '<STDIN>';
    return $stdin;
}

sub PT::ObjectFunctionCall::X {
    my ($class, $className) = @_;

    my $object = $class->{Object}->X($className);
    my $functionName = $class->{FunctionName}->X($className);

    my $objectFunctionCall;
    if(exists $class->{Parameters}) {
        my @parameters = @{$class->{Parameters}->X($className)};
        my $parameters = join(",", @parameters);
        $objectFunctionCall = "\$" . $object . "->" . $functionName . "(" . $parameters . ")";
    } else {
        $objectFunctionCall = "\$" . $object . "->" . $functionName . "()";
    }

    return $objectFunctionCall;
}

sub PT::ClassAccessor::X {
    my ($class, $className) = @_;
    my @classAccessorList = $class->{ClassAccessorList}->X($className);
    my $classAccessor = '$class->{"' . $className . '"}';

    foreach my $element (@classAccessorList) {
        $classAccessor .= '->{"' . $element . '"}';
    }

    return $classAccessor;
}

sub PT::ClassAccessorList::X {
    my ($class, $className) = @_;

    my @classAccessorList;
    for my $element (@{ $class->{HashName} }) {
        push @classAccessorList, $element->X($className);
    }

    return @classAccessorList;
}

sub PT::ClassFunctionCall::X {
    my ($class, $className) = @_;
    my $functionName = $class->{FunctionName}->X($className);
    my @parameters;
    my $parameters = "";
    if(exists $class->{Parameters}) {
        @parameters = @{$class->{Parameters}->X($className)};
        $parameters = join(",", @parameters);
    }

    my $classFunctionReturn = '$class->' . $functionName . '('. $parameters .');';
    return $classFunctionReturn;
}

sub PT::ClassFunctionReturn::X {
    my ($class, $className) = @_;
    my $functionName = $class->{FunctionName}->X($className);
    my @parameters;
    my $parameters = "";

    if(exists $class->{Parameters}) {
        @parameters = @{$class->{Parameters}->X($className)};
        $parameters = join(",", @parameters);
    }

    my $classFunctionReturn = '$class->' . $functionName . '('. $parameters .')';
    return $classFunctionReturn;
}

sub PT::FunctionReturn::X {
    my ($class, $className) = @_;
    my $functionName = $class->{FunctionName}->X($className);

    my $functionReturn = $functionName . "(" ;

    if(exists $class->{Parameters}) {
        my @parameters = @{$class->{Parameters}->X($className)};
        my $parameters = join(",", @parameters);
        $functionReturn .= $parameters;
    }

    $functionReturn .= ")";
    return $functionReturn;
}

sub PT::ArrayElement::X {
    my ($class, $className) = @_;
    my $arrayName = $class->{ArrayName}->X($className);
    my @accessList;

    for my $element (@{ $class->{ArrayAccess} }) {
        push @accessList, $element->X($className);
    }

    my $arrayElement =  "\$" . $arrayName;
    foreach my $element (@accessList) {
        $arrayElement .= $element;
    }

    return $arrayElement;
}

sub PT::ArrayAccess::X {
    my ($class, $className) = @_;

    return (       $class->{ArrayAccessElement}
                || $class->{ArrayAccessHash} )->X($className);
}

sub PT::ArrayAccessElement::X {
    my ($class, $className) = @_;
    my $arrayKey = $class->{ArrayKey}->X($className);
    my $arrayAccessElement = "->[" . $arrayKey . "]";
    return $arrayAccessElement;
}

sub PT::ArrayAccessHash::X {
    my ($class, $className) = @_;
    my $hashKey = $class->{HashKey}->X($className);
    my $arrayAccessHash = "->{" . $hashKey . "}";
    return $arrayAccessHash;
}

sub PT::ArrayKey::X {
    my ($class, $className) = @_;
    return (       $class->{Number}
                || $class->{ScalarVariable}
                || $class->{StructAccess}
                || $class->{ArrayElement}
                || $class->{HashElement}
                || $class->{FunctionReturn}
                || $class->{ClassFunctionReturn} )->X($className);
}

sub PT::ArrayName::X {
    my ($class, $className) = @_;
    my $arrayName = $class->{''};
    return $arrayName;
}

sub PT::HashElement::X {
    my ($class, $className) = @_;
    my $hashName = $class->{HashName}->X($className);
    my @accessList;

    for my $element (@{ $class->{HashAccess} }) {
        push @accessList, $element->X($className);
    }

    my $hashElement = "\$" . $hashName;
    foreach my $element (@accessList) {
        $hashElement .= $element;
    }

    return $hashElement;
}

sub PT::HashAccess::X {
    my ($class, $className) = @_;

    return (       $class->{HashAccessElement}
                || $class->{HashAccessArray} )->X($className);
}

sub PT::HashAccessElement::X {
    my ($class, $className) = @_;

    my $hashKey = $class->{HashKey}->X($className);
    my $hashAccessElement = "->{" . $hashKey . "}";
    return $hashAccessElement;
}

sub PT::HashAccessArray::X {
    my ($class, $className) = @_;

    my $arrayKey = $class->{ArrayKey}->X($className);
    my $hashAccessArray = "->[" . $arrayKey . "]";
    return $hashAccessArray;
}

sub PT::HashName::X {
    my ($class, $className) = @_;
    my $hashName = $class->{''};
    return $hashName;
}

sub PT::HashKey::X {
    my ($class, $className) = @_;
    return (       $class->{String}
                || $class->{Number}
                || $class->{ScalarVariable}
                || $class->{ArrayElement}
                || $class->{HashElement}
                || $class->{FunctionReturn}
                || $class->{ClassFunctionReturn} )->X($className);
}

sub PT::HashKeyString::X {
    my ($class, $className) = @_;

    my $hashKeyStringValue = "\"";
    $hashKeyStringValue .= $class->{HashKeyStringValue}->X($className);
    $hashKeyStringValue .= "\"";

    return $hashKeyStringValue;
}

sub PT::HashKeyStringValue::X {
    my ($class, $className) = @_;
    my $hashKeyStringValue = $class->{''};
    return $hashKeyStringValue;
}

sub PT::HashKeyNumber::X {
    my ($class, $className) = @_;
    my $hashKeyNumber = $class->{''};
    return $hashKeyNumber;
}

sub PT::ArrayAssignment::X {
    my ($class, $className) = @_;
    my $arrayElement = $class->{ArrayElement}->X($className);
    my $rhs = $class->{RHS}->X($className);

    my $arrayAssignment = $arrayElement . " = " . $rhs . ";\n";
    return $arrayAssignment;
}

sub PT::HashAssignment::X {
    my ($class, $className) = @_;
    my $hashElement = $class->{HashElement}->X($className);
    my $rhs = $class->{RHS}->X($className);

    my $hashAssignment = $hashElement . " = " . $rhs . ";\n";
    return $hashAssignment;
}

sub PT::Calc::X {
    my ($class, $className) = @_;
    my $calcExpression = $class->{CalcExpression}->X($className);
    return $calcExpression;
}

sub PT::CalcExpression::X {
    my ($class, $className) = @_;
    my @calcOperands;
    my @calcOperator;

    for my $element (@{ $class->{CalcOperands} }) {
        push @calcOperands, $element->X($className);
    }

    for my $element (@{ $class->{CalcOperator} }) {
        push @calcOperator, $element->X($className);
    }

    my $calcExpression = $calcOperands[0];
    for my $counter (1 .. $#calcOperands) {
        $calcExpression .= $calcOperator[$counter - 1] . " " . $calcOperands[$counter];
    }

    return $calcExpression;
}

sub PT::CalcOperands::X {
    my ($class, $className) = @_;
    return (       $class->{RealNumber}
                || $class->{ScalarVariable}
                || $class->{StructAccess}
                || $class->{ArrayElement}
                || $class->{HashElement}
                || $class->{ClassAccessor}
                || $class->{ClassFunctionReturn}
                || $class->{FunctionReturn}
                || $class->{EmbedBlock}
                || $class->{ObjectFunctionCall} )->X($className);
}

sub PT::CalcOperator::X {
    my ($class, $className) = @_;
    return (       $class->{Plus}
                || $class->{Minus}
                || $class->{Multiply}
                || $class->{Divide}
                || $class->{EmbedBlock} )->X($className);
}

sub PT::Return::X {
    my ($class, $className) = @_;
    if(exists $class->{RHS}) {
        my $rhs = $class->{RHS}->X($className);
        my $return = "return " . $rhs . ";\n";
        return $return;
    } else {
        return "return;";
    }
}

sub PT::Last::X {
    my ($class, $className) = @_;
    return "last;";
}

sub PT::Next::X {
    my ($class, $className) = @_;
    return "next;";
}

sub PT::GreaterThan::X {
    my ($class, $className) = @_;
    my $greaterThan = $class->{''};
    return $greaterThan;
}

sub PT::LessThan::X {
    my ($class, $className) = @_;
    my $lessThan = $class->{''};
    return $lessThan;
}

sub PT::Equals::X {
    my ($class, $className) = @_;
    my $equals = $class->{''};
    return $equals;
}

sub PT::Plus::X {
    my ($class, $className) = @_;
    my $plus = $class->{''};
    return $plus;
}

sub PT::Minus::X {
    my ($class, $className) = @_;
    my $minus = $class->{''};
    return $minus;
}

sub PT::Multiply::X {
    my ($class, $className) = @_;
    my $multiply = $class->{''};
    return $multiply;
}

sub PT::Divide::X {
    my ($class, $className) = @_;
    my $divide = $class->{''};
    return $divide;
}

sub PT::Modulus::X {
    my ($class, $className) = @_;
    my $divide = $class->{''};
    return $divide;
}

sub PT::Exponent::X {
    my ($class, $className) = @_;
    my $divide = $class->{''};
    return $divide;
}

sub PT::GreaterThanEquals::X {
    my ($class, $className) = @_;
    my $greaterThanEquals = $class->{''};
    return $greaterThanEquals;
}

sub PT::LessThanEquals::X {
    my ($class, $className) = @_;
    my $lessThanEquals = $class->{''};
    return $lessThanEquals;
}

sub PT::StringEquals::X {
    my ($class, $className) = @_;
    my $stringEquals = $class->{''};
    return $stringEquals;
}

sub PT::Percent::X {
    my ($class, $className) = @_;
    my $percent = $class->{''};
    return $percent;
}

sub PT::StringNotEquals::X {
    my ($class, $className) = @_;
    my $stringNotEquals = $class->{''};
    return $stringNotEquals;
}

sub PT::NotEqulas::X {
    my ($class, $className) = @_;
    my $notEqulas = $class->{''};
    return $notEqulas;
}

sub PT::LogicalAnd::X {
    my ($class, $className) = @_;
    my $logicalAnd = $class->{''};
    return $logicalAnd;
}

sub PT::LogicalOr::X {
    my ($class, $className) = @_;
    my $logicalOr = $class->{''};
    return $logicalOr;
}

sub PT::TokenImplement::X {
    my ($class, $className) = @_;
    my $tokenImplement = $class->{''};
    return $tokenImplement;
}

sub PT::TokenTry::X {
    my ($class, $className) = @_;
    my $tokenTry = $class->{''};
    return $tokenTry;
}

sub PT::TokenCatch::X {
    my ($class, $className) = @_;
    my $tokenCatch = $class->{''};
    return $tokenCatch;
}

sub PT::TokenError::X {
    my ($class, $className) = @_;
    my $tokenError = $class->{''};
    return $tokenError;
}

sub PT::EachSymbol::X {
    my ($class, $className) = @_;
    my $eachSymbol = $class->{''};
    return $eachSymbol;
}

sub PT::LParen::X {
    my ($class, $className) = @_;
    my $lParen = $class->{''};
    return $lParen;
}

sub PT::LParenError::X {
    my ($class, $className) = @_;
    my $lParenError = $class->{''};

    print "SyntaxError", "\n";
    print "===========", "\n";
    die "Missing ( after className '", $className, "', instead found ", $lParenError, "\n";
}

sub PT::LBrace::X {
    my ($class, $className) = @_;
    my $lBrace = $class->{''};
    return $lBrace;
}

sub PT::LBraceError::X {
    my ($class, $className) = @_;
    my $classLBraceError = $class->{''};
    return $classLBraceError;
}

sub PT::RBrace::X {
    my ($class, $className) = @_;
    my $rBrace = $class->{''};
    return $rBrace;
}

sub PT::RBraceError::X {
    my ($class, $className) = @_;
    my $classRBraceError = $class->{''};
    return $classRBraceError;
}

my $parser = qr {
    <nocontext:>
    # <debug: on>

    <Lang>
    <objrule:  PT::Lang>                       <[ClassOrStruct]>+
    <objrule:  PT::ClassOrStruct>              <DefineClass> | <DefineStruct>
    <objrule:  PT::DefineClass>                <[Class]>+

    <objrule:  PT::DefineStruct>               <[Struct]>+
    <objrule:  PT::Struct>                     <TokenStruct> <StructName> <LBrace> <StructElements> <RBrace> <SemiColon>
    <objrule:  PT::StructElements>             <[StructElement]>+ % <Comma>
    <objrule:  PT::StructElement>              <StructKey> | <StructStructElement>
    <objtoken: PT::StructKey>                  [a-zA-Z]+?
    <objrule:  PT::StructStructElement>        <StructVariable> <TokenStruct> <Dot> <StructName>
    <objtoken: PT::StructName>                 [A-Z][a-zA-Z]+?
    <objrule:  PT::MakeStruct>                 <TokenStruct> <Dot> <StructName> <LParen> <RParen>
    <objrule:  PT::StructAssignment>           <Var> <StructVariable> <Equal> <MakeStruct> <SemiColon>
    <objrule:  PT::StructAccess>               <StructVariable> <Dot> <StructAccessList>
    <objrule:  PT::StructAccessList>           <[StructAccessElement]>+ % <Dot>
    <objrule:  PT::StructAccessElement>        <StructVariable> | <StructKey>
    <objtoken: PT::StructVariable>             [a-zA-Z]+?

    <objrule:  PT::Class>                      <ws: (\s++)*> <TokenClass> <ClassName> <ClassBlock>
    <objrule:  PT::ClassName>                  [a-zA-Z]+?

    <objrule:  PT::ClassBlock>                 <ClassLBrace> <ClassGroups> <ClassRBrace>
    <objrule:  PT::ClassLBrace>                <LBrace> | <ClassLBraceError> | <MissingLBrace>
    <objrule:  PT::ClassRBrace>                <RBrace> | <ClassRBraceError> | <MissingRBrace>

    <objrule:  PT::ClassLBraceError>           <LBraceError>
    <objrule:  PT::ClassRBraceError>           <RBraceError>

    <objrule:  PT::ClassGroups>                <[Group]>+
    <objrule:  PT::Group>                      <Comment> | <Parent> | <Packages> | <EmbedBlock>
                                               | <ImplementFunction> | <Function> | <NonSyntaxClass>

    <objtoken: PT::NonSyntaxClass>             \b.*\b

    <objrule:  PT::ImplementFunction>          <TokenImplement> <TokenFunction> <FunctionName> <LParen> <FunctionParamList> <RParen> <LBrace> <MultiLineComment> <RBrace>
    <objrule:  PT::MultiLineComment>           <MLCommentBegin> <MLComment> <MLCommentEnd>
    <objtoken: PT::MLCommentBegin>             \/\*
    <objtoken: PT::MLCommentEnd>               \*\/
    <objrule:  PT::MLComment>                  .*?

    <objrule:  PT::Comment>                    [#] <LineComment> @
    <objtoken: PT::LineComment>                .*?

    <objrule:  PT::Parent>                     <TokenParent> <LParen> <ClassNames> <RParen> <SemiColon>
    <objrule:  PT::ClassNames>                 <[ClassName]>+ % <Comma>

    <objrule:  PT::Packages>                   <LParen> <PackageList> <RParen> <SemiColon>
    <objrule:  PT::PackageList>                <[Package]>+ % <Comma>
    <objrule:  PT::Package>                    <PackageWithConstructor> | <PackageWithoutConstructor>
    <objrule:  PT::PackageWithConstructor>     <Object> <Equal> <Asterisk>? <PackageName> <Dot> <Constructor> <LParen> <ObjectParameters>? <RParen>
    <objrule:  PT::ObjectParameters>           <Parameters>
    <objrule:  PT::PackageName>                <[PackageDir]>+ % (::)
    <objrule:  PT::PackageWithoutConstructor>  <PackageName> <QW>?
    <objrule:  PT::QW>                         <Dot> <LParen> <FunctionList> <RParen>
    <objrule:  PT::FunctionList>               <[FunctionName]>+ % <Comma>
    <objrule:  PT::Constructor>                [a-zA-Z]+?
    <objrule:  PT::Object>                     [a-zA-Z]+?
    <objrule:  PT::PackageDir>                 [a-zA-Z0-9_]+?
    <objrule:  PT::ParamsNotHash>              <LessThan> <PackageParams> <GreaterThan>
    <objrule:  PT::PackageParams>              <[KeyValue]>+ % <Comma>

    <objrule:  PT::Function>                   <TokenFunction> <FunctionName> <LParen> <FunctionParamList> <RParen> <CodeBlock>
    <objtoken: PT::FunctionName>               [A-Za-z_]+?

    <objrule:  PT::FunctionParamList>          <EmptyParamList> | <FunctionParams>
    <objtoken: PT::EmptyParamList>             .{0}
    <objrule:  PT::FunctionParams>             <[Arg]>+ % <Comma>
    <objrule:  PT::Arg>                        [a-zA-Z]+?

    <objrule:  PT::CodeBlock>                  <LBrace> <Blocks> <RBrace>
    <objrule:  PT::Blocks>                     <[Block]>+

    <objrule:  PT::Block>                      <IfElse> | <While> | <ForEach> | <For> | <ArrayEach> | <HashEach> | <EmbedBlock>
                                               | <Comment> | <Statement> | <TryCatch> | <RegexMatch> | <Packages> | <NonSyntaxFunction>

    <objtoken: PT::NonSyntaxFunction>          \b.*\b

    <objrule:  PT::TryCatch>                   <TokenTry> <CodeBlock> <CatchBlock>?
    <objrule:  PT::CatchBlock>                 <TokenCatch> <LParen> <TokenError> <RParen> <CodeBlock>

    <objrule:  PT::EmbedBlock>                 <TokenEmbedBlock> <EmbedCodeBlock>
    <objrule:  PT::EmbedCodeBlock>             <EmbedBegin> <EmbeddedCode> <EmbedEnd>
    <objrule:  PT::EmbedBegin>                 <LParen>\?
    <objrule:  PT::EmbedEnd>                   \?<RParen>
    <objrule:  PT::EmbeddedCode>               (?<=\(\?)\s*.*?\s*(?=\?\))

    <objrule:  PT::While>                      <TokenWhile> <LParen> <BoolExpression> <RParen> <CodeBlock>
    <objrule:  PT::ForEach>                    <TokenForeach> <LParen> <ForRange> <RParen> <EachSymbol> <VariableName> <CodeBlock>

    <objrule:  PT::ArrayEach>                  <TokenArrayEach> <LParen> <VariableName> <RParen> <EachSymbol> <LParen> <ArrayEachVariableName> <Comma> <ArrayEachNumber> <RParen> <CodeBlock>
    <objrule:  PT::ArrayEachVariableName>      <VariableName>
    <objrule:  PT::ArrayEachNumber>            <VariableName>

    <objrule:  PT::HashEach>                   <TokenHashEach> <LParen> <VariableName> <RParen> <EachSymbol> <LParen> <HashEachKey> <Comma> <HashEachValue> <RParen> <CodeBlock>
    <objrule:  PT::HashEachKey>                <VariableName>
    <objrule:  PT::HashEachValue>              <VariableName>

    <objrule:  PT::For>                        <TokenFor> <Var> <VariableName> <LParen> <ForRange> <RParen> <CodeBlock>
    <objrule:  PT::ForRange>                   <LowerRange> <Dot><Dot><Dot> <UpperRange>

    <objrule:  PT::LowerRange>                 <String> | <Number> | <VariableName> | <ArrayElement> | <HashElement>
                                               | <StructAccess> | <ClassAccessor> | <ClassFunctionReturn> | <FunctionReturn>

    <objrule:  PT::UpperRange>                 <String> | <Number> | <VariableName> | <ArrayElement> | <HashElement>
                                               | <StructAccess> | <ClassAccessor> | <ClassFunctionReturn> | <FunctionReturn>

    <objrule:  PT::RegexMatch>                 <TokenMatchRegex> <LParen> <Pattern> <RegexMatchSymbol> <MatchString> <RParen> <CodeBlock>
    <objrule:  PT::Pattern>                    <VariableName>
    <objrule:  PT::MatchString>                <VariableName>

    <objrule:  PT::IfElse>                     <If> <ElsIf>? <Else>?
    <objrule:  PT::If>                         <TokenIf> <LParen> <BoolExpression> <RParen> <CodeBlock>

    <objrule:  PT::BoolExpression>             <[BooleanExpression]>+ % <[BoolOperator]>
    <objrule:  PT::BooleanExpression>          <BoolOperands> <BoolOperatorExpression>?
    <objrule:  PT::BoolOperatorExpression>     <BoolOperator> <BoolOperands>

    <objrule:  PT::BoolOperands>               <RealNumber> | <String> | <ScalarVariable> | <ArrayElement> | <HashElement> | <StructAccess>
                                               | <ClassAccessor> | <ClassFunctionReturn> | <FunctionReturn> | <EmbedBlock>

    <objrule:  PT::BoolOperator>               <GreaterThan> | <LessThan> | <Equals> | <GreaterThanEquals> | <LessThanEquals> | <Percent>
                                               | <StringEquals> | <StringNotEquals> | <NotEqulas> | <LogicalAnd> | <LogicalOr>
                                               | <EmbedBlock>

    <objrule:  PT::ElsIf>                      <[ElsIfChain]>+
    <objrule:  PT::ElsIfChain>                 <TokenElsIf> <LParen> <BoolExpression> <RParen> <CodeBlock>
    <objrule:  PT::Else>                       <TokenElse> <CodeBlock>

    <objrule:  PT::Statement>                  <FunctionReferenceCallStatement> | <StructAssignment> | <VariableDeclaration> | <Regex> | <FunctionCall>
                                               | <ClassFunctionCall> | <ObjectCall> | <Assignment> | <Return>
                                               | <Last> | <Next> | <PackageFunctionStatement> | <PackageNameStatement>

    <objrule:  PT::PackageFunctionStatement>   <PackageFunction> <SemiColon>
    <objrule:  PT::PackageFunction>            <PackageName> <LParen> <Parameters>? <RParen>

    <objrule:  PT::PackageNameStatement>       <PackageName> <SemiColon>

    <objrule:  PT::Regex>                      <TokenMakeRegex> <LParen> <RegexVariable> <Comma> <Regexp> <Comma> <Modifiers> <RParen> <SemiColon>
    <objrule:  PT::RegexVariable>              <VariableName>
    <objrule:  PT::Regexp>                     <BackSlash> <Pre> <BackSlash>
    <objrule:  PT::Pre>                        (?<=\/)\s*.*?\s*(?=\/\,)
    <objrule:  PT::Modifiers>                  <LParen> <RegexModifiers> <RParen>
    <objtoken: PT::RegexModifiers>             [nmasdilxpu]+

    <objrule:  PT::ClassFunctionCall>          <TokenClass> <Dot> <FunctionName> <LParen> <Parameters>? <RParen> <SemiColon>

    <objrule:  PT::ObjectCall>                 <ObjectFunctionCall> <SemiColon>
    <objrule:  PT::VariableDeclaration>        <ArrayDeclaration> | <HashDeclaration> | <ScalarDeclaration>

    <objrule:  PT::ScalarDeclaration>          <Var> <VariableName> <Equal> <Value> <SemiColon>
    <objtoken: PT::Var>                        var
    <objtoken: PT::VariableName>               [a-zA-Z_]+?
    <objrule:  PT::Value>                      <RHS>
    <objtoken: PT::Number>                     [0-9]+
    <objtoken: PT::RealNumber>                 [-]?[0-9]+\.?[0-9]+|[0-9]+
    <objrule:  PT::String>                     <Quote> <StringValue> <Quote>
    <objtoken: PT::StringValue>                (?<=")\s*.*?\s*(?=")

    <objrule:  PT::ArrayDeclaration>           <Var> <VariableName> <Equal> <ArrayList> <SemiColon>
    <objrule:  PT::ArrayList>                  <LBracket> <ListElements> <RBracket>
    <objrule:  PT::ListElements>               .{0} | <[ListElement]>+ % <Comma>

    <objrule:  PT::ListElement>                <RealNumber> | <String> | <ClassFunctionReturn> | <FunctionReturn>
                                                | <ArrayElement> | <HashElement> | <ArrayList> | <HashRef> | <StructAccess>
                                                | <VariableName> |  <ClassAccessor> | <ObjectFunctionCall> | <EmbedBlock>

    <objrule:  PT::HashDeclaration>            <Var> <VariableName> <Equal> <HashRef> <SemiColon>
    <objrule:  PT::HashRef>                    <LBrace> <KeyValuePairs> <RBrace>
    <objrule:  PT::KeyValuePairs>              .{0} | <[KeyValue]>+ % <Comma>
    <objrule:  PT::KeyValue>                   <PairKey> <Colon> <PairValue>

    <objrule:  PT::PairKey>                    <Number> | <String> | <ClassFunctionReturn> | <FunctionReturn>
                                                | <StructAccess> | <VariableName> | <EmbedBlock>

    <objrule:  PT::PairValue>                  <RealNumber> | <String> | <ClassFunctionReturn> | <FunctionReturn> | <StructAccess>
                                                | <FunctionReference> | <ArrayElement> | <HashElement> | <ArrayList> | <HashRef>
                                                | <ClassAccessor> | <VariableName> | <ObjectFunctionCall> | <PackageFunction> | <EmbedBlock>

    <objrule:  PT::FunctionCall>               <FunctionName> <LParen> <Parameters>? <RParen> <SemiColon>
    <objrule:  PT::Parameters>                 <[Param]>+ % <Comma>
    <objrule:  PT::Param>                      <RealNumber> | <String> | <StructAccess> | <VariableName> | <ArrayElement> | <HashElement> | <ClassAccessor> | <PerlObject>
                                               | <ParamsNotHash> | <HashRef> | <FunctionReturn> | <ClassFunctionReturn> | <EmbedBlock>
                                               | <FunctionReference> | <ClassFunctionReturn> | <Calc> | <ParamChars> | <ObjectFunctionCall>

    <objrule:  PT::PerlObject>                 <Exclamation> <PerlObjectName>
    <objrule:  PT::PerlObjectName>             [a-zA-Z]+?

    <objrule:  PT::ParamChars>                 <SingleQuote> <ParamCharacters> <SingleQuote>
    <objtoken: PT::ParamCharacters>            [A-Za-z]+?

    <objrule:  PT::Assignment>                 <StructAssignmentStatement> | <ScalarAssignment> | <ArrayAssignment> | <HashAssignment> | <AccessorAssignment>
    <objrule:  PT::StructAssignmentStatement>  <StructAccess> <Equal> <RHS> <SemiColon>

    <objrule:  PT::ScalarAssignment>           <ScalarVariable> <Equal> <RHS> <SemiColon>
    <objtoken: PT::ScalarVariable>             [a-zA-Z]+

    <objrule:  PT::RHS>                        <RealNumber> | <StructAccess> | <FunctionReference> | <FunctionReturn> | <ArrayElement> | <HashElement>
                                               | <ScalarVariable> | <Calc> | <ArrayList> | <HashRef> | <ClassAccessor>
                                               | <ClassFunctionReturn> | <FunctionReferenceCall> | <ParamChars>
                                               | <String> | <STDIN> | <RegexMatchVariables> | <ObjectFunctionCall> | <EmbedBlock>

    <objrule:  PT::RegexMatchVariables>        <RegexMatchSymbol> <MatchVariable>
    <objrule:  PT::MatchVariable>              <Number> | <MatchParts>
    <objtoken: PT::MatchParts>                 PREMATCH|MATCH|POSTMATCH

    <objrule:  PT::FunctionReference>          <TokenReference> <TokenClass> <Dot> <FunctionName> <LParen> <Parameters>? <RParen>
    <objrule:  PT::FunctionReferenceCall>      <TokenReferenceCall> <FunctionName> <LParen> <Parameters>? <RParen>

    <objrule:  PT::FunctionReferenceCallStatement>      <FunctionReferenceCall> <SemiColon>

    <objrule:  PT::FunctionReturn>             <FunctionName> <LParen> <Parameters>? <RParen>

    <objrule:  PT::ArrayElement>               <ArrayName> <[ArrayAccess]>+
    <objrule:  PT::ArrayAccess>                <ArrayAccessElement> | <ArrayAccessHash>
    <objrule:  PT::ArrayAccessElement>         <LBracket> <ArrayKey> <RBracket>
    <objrule:  PT::ArrayAccessHash>            <LBrace> <HashKey> <RBrace>

    <objrule:  PT::ArrayKey>                   <Number> | <ScalarVariable> | <ArrayElement> | <StructAccess>
                                               | <HashElement> | <FunctionReturn> | <ClassFunctionReturn>
    <objrule:  PT::ArrayName>                  [a-zA-Z]+?

    <objrule:  PT::HashElement>                <HashName> <[HashAccess]>+
    <objrule:  PT::HashAccess>                 <HashAccessElement> | <HashAccessArray>
    <objrule:  PT::HashAccessElement>          <LBrace> <HashKey> <RBrace>
    <objrule:  PT::HashAccessArray>            <LBracket> <ArrayKey> <RBracket>
    <objtoken: PT::HashName>                   [a-zA-Z]+?
    <objrule:  PT::HashKey>                    <String> | <Number> | <ScalarVariable> | <ArrayElement>
                                               | <HashElement> | <FunctionReturn> | <ClassFunctionReturn>

    <objrule:  PT::STDIN>                      <LessThan> <TokenSTDIN> <GreaterThan>

    <objtoken: PT::HashKeyStringValue>         [a-zA-Z]+?
    <objrule:  PT::AccessorAssignment>         <TokenClass> <Dot> <HashKeyStringValue> <Equal> <RHS> <SemiColon>
    <objrule:  PT::ClassAccessor>              <TokenClass> <Dot> <ClassAccessorList>
    <objrule:  PT::ClassAccessorList>          <[HashName]>+ % <Dot>

    <objrule:  PT::ClassFunctionReturn>        <TokenClass> <Dot> <FunctionName> <LParen> <Parameters>? <RParen>
    <objrule:  PT::ArrayAssignment>            <ArrayElement> <Equal> <RHS> <SemiColon>
    <objrule:  PT::HashAssignment>             <HashElement> <Equal> <RHS> <SemiColon>

    <objrule:  PT::Calc>                       <CalcExpression>
    <objrule:  PT::CalcExpression>             <[CalcOperands]>+ % <[CalcOperator]>
    <objrule:  PT::CalcOperands>               <RealNumber> | <ScalarVariable> | <ArrayElement> | <HashElement> | <ClassAccessor>
                                               | <StructAccess> | <ClassFunctionReturn> | <FunctionReturn> | <EmbedBlock> | <ObjectFunctionCall>

    <objtoken: PT::CalcOperator>               <Plus> | <Minus> | <Multiply> | <Divide> | <Modulus> | <Exponent> | <EmbedBlock>

    <objrule:  PT::Return>                     <TokenReturn> <RHS>? <SemiColon>
    <objrule:  PT::Last>                       <TokenLast> <SemiColon>
    <objrule:  PT::Next>                       <TokenNext> <SemiColon>

    <objrule:  PT::ObjectFunctionCall>         <Object> <Dot> <FunctionName> <LParen> <Parameters>? <RParen>

    <objtoken: PT::TokenReturn>                return
    <objtoken: PT::TokenNext>                  next
    <objtoken: PT::TokenLast>                  last
    <objtoken: PT::TokenElse>                  else
    <objtoken: PT::TokenElsIf>                 elsif
    <objtoken: PT::TokenIf>                    if
    <objtoken: PT::TokenFor>                   for
    <objtoken: PT::TokenForeach>               forEach
    <objtoken: PT::TokenWhile>                 while
    <objtoken: PT::TokenFunction>              function
    <objtoken: PT::TokenParent>                parent
    <objtoken: PT::TokenClass>                 class
    <objtoken: PT::TokenEmbedBlock>            embed
    <objtoken: PT::TokenSTDIN>                 STDIN
    <objtoken: PT::TokenNot>                   not
    <objtoken: PT::TokenArrayEach>             arrayEach
    <objtoken: PT::TokenHashEach>              hashEach
    <objtoken: PT::TokenImplement>             implement
    <objtoken: PT::TokenTry>                   try
    <objtoken: PT::TokenCatch>                 catch
    <objtoken: PT::TokenError>                 error
    <objtoken: PT::TokenMakeRegex>             makeRegex
    <objtoken: PT::TokenMatchRegex>            matchRegex
    <objtoken: PT::TokenReference>             reference
    <objtoken: PT::TokenReferenceCall>         referenceCall
    <objtoken: PT::TokenStruct>                struct

    <objtoken: PT::Exclamation>                \!
    <objtoken: PT::BackSlash>                  \/
    <objtoken: PT::Percent>			           \%
    <objtoken: PT::RegexMatchSymbol>           \@
    <objtoken: PT::EachSymbol>                 =\>
    <objtoken: PT::Ampersand>                  \&
    <objtoken: PT::Asterisk>                   \*
    <objtoken: PT::Modulus>                    \%
    <objtoken: PT::Exponent>                   \*\*
    <objtoken: PT::LogicalAnd>                 \&\&
    <objtoken: PT::LogicalOr>                  \|\|
    <objtoken: PT::NotEqulas>                  \!=
    <objtoken: PT::StringNotEquals>            ne
    <objtoken: PT::StringEquals>               eq
    <objtoken: PT::LessThanEquals>             \<=
    <objtoken: PT::GreaterThanEquals>          \>=
    <objtoken: PT::GreaterThan>                \>
    <objtoken: PT::LessThan>                   \<
    <objtoken: PT::Equals>                     ==
    <objtoken: PT::Plus>                       \+
    <objtoken: PT::Minus>                      \-
    <objtoken: PT::Multiply>                   \*
    <objtoken: PT::Divide>                     \/
    <objtoken: PT::Quote>                      "
    <objtoken: PT::SingleQuote>                '
    <objtoken: PT::SemiColon>                  ;
    <objtoken: PT::Colon>                      :
    <objtoken: PT::Dot>                        \.
    <objtoken: PT::Equal>                      =
    <objtoken: PT::Comma>                      ,
    <objtoken: PT::LParen>                     \(
    <objtoken: PT::RParen>                     \)
    <objtoken: PT::LBrace>                     \{
    <objtoken: PT::LBraceError>                \s.
    <objtoken: PT::RBrace>                     \}
    <objtoken: PT::RBraceError>                \s*.
    <objtoken: PT::LBracket>                   \[
    <objtoken: PT::RBracket>                   \]

    <objtoken: PT::MissingLBrace>              .{0}
    <objtoken: PT::MissingRBrace>              .{0}
}xms;

sub parse {
    my ($class, $program) = @_;
    if($program =~ $parser) {
        my $code = $/{Lang}->X();
        return $code;
    } else {
        my $notMatch = "print 'Error';";
        return $notMatch;
    }
}

1;

__END__


=head1 NAME

Lang::HL HL programming language.

=head1 SYNOPSIS

  $> hlc <directoryName>
  $> hlp <directoryName>

=head1 DESCRIPTION

HL is a programming language.

=head1 EXAMPLE

    class Main {
    	(JSON,
    	 !mechanize = WWW::Mechanize.new());

    	function main() {
    		class.counter = 0;

    		var hash = class.returnNumber();
    		var json = encode_json(hash);
    		print(json, "\n");

    		var url = "https://metacpan.org/pod/WWW::Mechanize";
    		!mechanize.get(url);
    		var page = !mechanize.text();
    		print(page, "\n");
    	}

    	function returnNumber() {
    		var number = {};

    		if(class.counter < 10) {
    			class.counter = class.counter + 1;

    			number = { "number" : class.returnNumber() };
    			return number;
    		}

    		return class.counter;
    	}
    }

=head1 AUTHOR

Rajkumar Reddy

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Rajkumar Reddy. All rights reserved.


=cut
