import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const spinnerVariants = cva(
  "animate-spin rounded-full border-2 border-current border-t-transparent",
  {
    variants: {
      size: {
        sm: "h-4 w-4",
        default: "h-6 w-6",
        lg: "h-8 w-8",
      },
    },
    defaultVariants: {
      size: "default",
    },
  },
)

export interface SpinnerProps extends VariantProps<typeof spinnerVariants> {
  className?: string
}

function Spinner({ size, className }: SpinnerProps) {
  return (
    <div className={cn(spinnerVariants({ size }), className)} role="status" aria-label="Loading" />
  )
}

export { Spinner, spinnerVariants }
