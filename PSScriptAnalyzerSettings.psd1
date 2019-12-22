@{
	IncludeRules = @(
		'PSAvoidTrailingWhitespace'
		'PSAvoidAssignmentToAutomaticVariable'
		'PSAvoidDefaultValueForMandatoryParameter'
		'PSAvoidGlobalAliases'
		'PSAvoidGlobalFunctions'
		'PSAvoidGlobalVars'
		'PSAvoidUsingPositionalParameters'
		'PSUseCorrectCasing'
		'PSUseDeclaredVarsMoreThanAssignments'
		'PSPlaceCloseBrace'
		'PSPlaceOpenBrace'
	)
	ExcludeRules = @(
		'PSAvoidInvokingEmptyMembers'
		'PSAvoidUsingCmdletAliases'
		'PSUseSingularNouns'
		'PSAvoidUsingWriteHost'
		'PSUseOutputTypeCorrectly'
		'PSAvoidDefaultValueSwitchParameter'
		'PSUseShouldProcessForStateChangingFunctions'
		'PSAvoidUsingConvertToSecureStringWithPlainText'
		'PSAvoidUsingPlainTextForPassword'
		'PSPossibleIncorrectComparisonWithNull'
		'PSAlignAssignmentStatement'
	)
	Rules = @{
		PSPlaceOpenBrace = @{
			Enable = $True
			OnSameLine = $False
			NewLineAfter = $True
			IgnoreOneLineBlock = $True
		}
		PSPlaceCloseBrace = @{
			Enable = $True
			NewLineAfter = $True
			IgnoreOneLineBlock = $True
			NoEmptyLineBefore = $True
		}
	}
}
